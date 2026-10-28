-- ==========================================================
-- スモークテスト: 独自コマンド・特殊ディレクトリ・キーマップが生きているか
-- 実行: nvim --headless -c "luafile scripts/smoke.lua"
-- 失敗があれば exit 1。docs/04-verification.md の V-7
-- ==========================================================

local results = { passed = 0, failed = {} }

local function test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    results.passed = results.passed + 1
  else
    table.insert(results.failed, name .. ": " .. tostring(err))
  end
end

local function eq(actual, expected, msg)
  if not vim.deep_equal(actual, expected) then
    error(string.format("%s expected=%s actual=%s", msg or "", vim.inspect(expected), vim.inspect(actual)), 2)
  end
end

local function tmpdir(files)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  for name, content in pairs(files) do
    vim.fn.mkdir(vim.fs.dirname(dir .. "/" .. name), "p")
    vim.fn.writefile(vim.split(content, "\n"), dir .. "/" .. name)
  end
  return dir
end

-- ── 独自コマンド (plugin/workflow.lua) ──
test("user commands exist", function()
  local cmds = vim.api.nvim_get_commands({})
  for _, name in ipairs({ "Verify", "VerifyLog", "Spec", "Tasks", "Adr", "Plans", "SpecGrep", "Worktrees",
    "ClaudeNew", "ClaudeSessions", "Preview", "PreviewStop" }) do
    assert(cmds[name], "missing :" .. name)
  end
end)

test("lazy command stubs exist", function()
  local cmds = vim.api.nvim_get_commands({})
  for _, name in ipairs({ "ClaudeCode", "CodeDiff", "LivePreview", "Sv", "GrugFar", "G" }) do
    assert(cmds[name], "missing :" .. name)
  end
end)

-- ── verify の判定 ──
test("verify detects pnpm verify", function()
  local dir = tmpdir({ ["package.json"] = '{"scripts":{"verify":"echo ok"}}', ["pnpm-lock.yaml"] = "" })
  eq(require("workflow.verify").detect(dir), { "pnpm", "run", "verify" })
end)

test("verify detects make verify", function()
  local dir = tmpdir({ Makefile = "build:\n\techo\nverify:\n\techo ok" })
  eq(require("workflow.verify").detect(dir), { "make", "verify" })
end)

test("verify returns nil without runner", function()
  eq(require("workflow.verify").detect(tmpdir({ ["README.md"] = "x" })), nil)
end)

--- verify を実行して quickfix が埋まるまで待つ。実行中に cwd を switch_to へ切り替える
local function run_verify(start_dir, switch_to)
  local cwd = vim.fn.getcwd()
  vim.fn.setqflist({}, "f")
  vim.cmd.cd(start_dir)
  require("workflow.verify").run()
  if switch_to then
    vim.cmd.cd(switch_to)
  end
  local done = vim.wait(5000, function()
    local context = vim.fn.getqflist({ context = 0 }).context
    return type(context) == "table" and context.finished_at ~= nil and context.exit_code ~= nil
  end, 20)
  vim.cmd.cd(cwd)
  vim.cmd("silent! cclose")
  vim.cmd("silent! only")
  assert(done, "verify did not finish")
  return vim.tbl_filter(function(i) return i.valid == 1 end, vim.fn.getqflist())
end

-- #1: 実行中に cwd が変わっても、診断は実行元 (root) のファイルを指す
test("verify quickfix stays in the root it ran from", function()
  local a = vim.fn.resolve(tmpdir({ ["scripts/.keep"] = "" }))
  vim.fn.mkdir(a .. "/.git", "p")
  vim.fn.mkdir(a .. "/src", "p")
  vim.fn.mkdir(a .. "/sub", "p")
  vim.fn.writefile({ "package main" }, a .. "/src/main.go")
  vim.fn.writefile({
    "sleep 0.3",
    "echo 'src/main.go:1:1: error in A'",
    "echo '" .. a .. "/src/main.go:2:1: absolute'",
    "exit 1",
  }, a .. "/scripts/verify.sh")
  local b = vim.fn.resolve(tmpdir({ ["src/main.go"] = "package main" }))
  -- cwd がサブディレクトリでも root 基準で解決する
  local items = run_verify(a .. "/sub", b)
  eq(#items, 2)
  for _, item in ipairs(items) do
    eq(vim.fn.resolve(vim.api.nvim_buf_get_name(item.bufnr)), a .. "/src/main.go")
  end
  eq(vim.fn.getqflist({ context = 0 }).context.root, a)
end)

-- #2: 行の途中で切れた出力を行に戻してから quickfix に渡す
test("verify joins chunked output per stream", function()
  local a = vim.fn.resolve(tmpdir({ ["scripts/.keep"] = "" }))
  vim.fn.writefile({
    "mkdir -p src lib && touch src/main.go lib/x.go",
    "printf 'src/ma'",
    "printf 'lib/x.go:3:' >&2",
    "sleep 0.2",
    "printf 'in.go:1:1: chunked error\\n'",
    "printf '4: stderr error' >&2",
    "exit 1",
  }, a .. "/scripts/verify.sh")
  local items = run_verify(a)
  local got = vim.tbl_map(function(i)
    local name = vim.uv.fs_realpath(vim.api.nvim_buf_get_name(i.bufnr)) or vim.api.nvim_buf_get_name(i.bufnr)
    return name:sub(#vim.uv.fs_realpath(a) + 2) .. ":" .. i.lnum .. ":" .. i.text
  end, items)
  table.sort(got)
  eq(got, { "lib/x.go:3:stderr error", "src/main.go:1:chunked error" })
end)

-- #5: linter は識別名ではなく実行ファイル (cmd) の有無で判定する
test("lint runs golangci-lint when its command is on PATH", function()
  require("lazy").load({ plugins = { "nvim-lint" } })
  local lint = require("lint")
  local bin = tmpdir({ ["golangci-lint"] = "#!/bin/sh" })
  vim.fn.setfperm(bin .. "/golangci-lint", "rwxr-xr-x")
  local path, try_lint = vim.env.PATH, lint.try_lint
  local called = {}
  lint.try_lint = function(names) called = names end
  local function fire(env_path)
    vim.env.PATH = env_path
    called = {}
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = "go"
    vim.api.nvim_buf_call(buf, function()
      vim.api.nvim_exec_autocmds("BufWritePost", { group = "Linting", buffer = buf })
    end)
    vim.api.nvim_buf_delete(buf, { force = true })
    return called
  end
  local ok, err = pcall(function()
    eq(fire(bin .. ":" .. path), { "golangcilint" }, "with golangci-lint")
    eq(fire(tmpdir({ x = "" })), {}, "without golangci-lint")
  end)
  vim.env.PATH, lint.try_lint = path, try_lint
  assert(ok, err)
end)

-- ── project / worktree ──
test("agent worktree label", function()
  local project = require("workflow.project")
  eq(project.agent_name("/Users/x/devel/api/.claude/worktrees/agent-3f2a/src"), "agent-3f2a")
  eq(project.label("/Users/x/devel/api/.claude/worktrees/agent-3f2a"), "api:agent-3f2a")
  eq(project.label("/Users/x/devel/api"), "api")
end)

test("worktree list parses this repo", function()
  local list = require("workflow.worktree").list(vim.fn.stdpath("config"))
  assert(#list >= 1, "no worktrees")
  assert(list[1].path and list[1].branch, vim.inspect(list[1]))
end)

test("tabline renders", function()
  local out = require("workflow.tabline").render()
  assert(type(out) == "string" and out:find("TabLine"), out)
end)

-- ── 特殊ディレクトリ ──
test("ftdetect: .mmd is mermaid", function()
  eq(vim.filetype.match({ filename = "diagram.mmd" }), "mermaid")
  eq(vim.filetype.match({ filename = "compose.yaml" }), "yaml.docker-compose")
end)

test("after/ftplugin: markdown settings and checkbox toggle", function()
  local file = vim.fn.tempname() .. ".md"
  vim.fn.writefile({ "- [ ] task", "plain" }, file)
  vim.cmd.edit(file)
  eq(vim.wo.conceallevel, 2, "conceallevel")
  eq(vim.bo.shiftwidth, 2, "shiftwidth")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.api.nvim_feedkeys(vim.keycode("<Space>mx"), "x", false)
  eq(vim.api.nvim_get_current_line(), "- [x] task")
  -- ]] / [[ は Markdown では見出し移動 (runtime ftplugin のバッファマップがグローバルより優先)
  local nav = vim.fn.maparg("]]", "n", false, true)
  eq(nav.buffer, 1, "]] should be buffer-local in markdown")
  vim.cmd("bwipeout!")
end)

test("after/ftplugin: go uses tabs", function()
  local file = vim.fn.tempname() .. ".go"
  vim.cmd.edit(file)
  eq(vim.bo.expandtab, false)
  vim.cmd("bwipeout!")
end)

test("doc/: :help nvim-config resolves", function()
  vim.cmd("help nvim-config-grammar")
  eq(vim.fn.expand("%:t"), "nvim-config.txt")
  vim.cmd("close")
end)

test("snippets/: markdown snippets are valid JSON", function()
  local dir = vim.fn.stdpath("config") .. "/snippets/"
  for _, name in ipairs({ "package.json", "markdown.json", "all.json" }) do
    vim.json.decode(table.concat(vim.fn.readfile(dir .. name), "\n"))
  end
end)

-- ── quickfix の errorformat ──
test("verify errorformat parses go / tsc output", function()
  vim.fn.setqflist({}, " ", {
    lines = { "internal/a.go:12:5: undefined: foo", "src/b.ts(3,7): error TS2322: bad", "noise line" },
    efm = "%f:%l:%c: %m,%f(%l\\,%c): %m",
  })
  local valid = vim.tbl_filter(function(i) return i.valid == 1 end, vim.fn.getqflist())
  eq(#valid, 2)
end)

-- ── キーマップ (R-11: which-key から辿れる) ──
test("leader keymaps are registered", function()
  local want = { " ss", " st", " vv", " gw", " gd", " ac", " an", " mp", " ff", " e", " u", " rr" }
  local have = {}
  for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
    have[m.lhs:gsub("<Space>", " ")] = true
  end
  for _, lhs in ipairs(want) do
    assert(have[lhs], "missing keymap <leader>" .. vim.trim(lhs))
  end
end)

-- ── レッスン ──
test("lessons: list, open copy, progress", function()
  local lesson = require("workflow.lesson")
  local items = lesson.list()
  assert(#items >= 12, "lessons: " .. #items)
  eq(items[1].number, 0)
  for _, item in ipairs(items) do
    assert(item.total > 0, item.name .. " にチェックボックスが無い")
  end
  assert(vim.api.nvim_get_commands({}).Lesson, "missing :Lesson")
end)

-- ── Claude のコピー (R-09) ──
test("Claude clipboard does not leak Base64 into terminal", function()
  local result = vim.system({ vim.v.progpath, "--clean", "--headless", "-l",
    vim.fn.stdpath("config") .. "/scripts/claude-clipboard.lua" }, { text = true }):wait(15000)
  assert(result.code == 0, (result.stderr or "") .. (result.stdout or ""))
end)

-- ── 結果 ──
test("editor workflow regressions", function()
  local result = vim.system({ vim.v.progpath, "--clean", "--headless", "-l",
    vim.fn.stdpath("config") .. "/scripts/editor-regression.lua" }, { text = true }):wait(15000)
  assert(result.code == 0, (result.stderr or "") .. (result.stdout or ""))
end)

test("Verify keeps diagnostics and evidence in the originating worktree", function()
  local result = vim.system({ vim.v.progpath, "--clean", "--headless", "-l",
    vim.fn.stdpath("config") .. "/scripts/workflow-verify.lua" }, { text = true }):wait(15000)
  assert(result.code == 0, (result.stderr or "") .. (result.stdout or ""))
end)

test("verification harness rejects false green", function()
  local result = vim.system({ "bash", vim.fn.stdpath("config") .. "/scripts/verify-regression.sh" }, { text = true }):wait(15000)
  assert(result.code == 0, (result.stderr or "") .. (result.stdout or ""))
end)

test("setup preserves links and restores pinned plugins", function()
  local result = vim.system({ "bash", vim.fn.stdpath("config") .. "/scripts/terminal-tests.sh" }, { text = true }):wait(30000)
  assert(result.code == 0, (result.stderr or "") .. (result.stdout or ""))
end)

test("ws isolates projects and preserves existing sessions", function()
  for _, shell in ipairs({ "bash", "zsh" }) do
    if vim.fn.executable(shell) == 1 then
      local result = vim.system({ shell, vim.fn.stdpath("config") .. "/scripts/ws-regression.sh" }, { text = true }):wait(15000)
      assert(result.code == 0, shell .. ": " .. (result.stderr or "") .. (result.stdout or ""))
    end
  end
end)

local total = results.passed + #results.failed
io.write(string.format("smoke: %d/%d passed\n", results.passed, total))
for _, f in ipairs(results.failed) do
  io.write("  ✗ " .. f .. "\n")
end
vim.cmd(#results.failed == 0 and "qa!" or "cq!")
