-- R-02/R-04/R-05/R-21: 図・資料・外部ツールの境界を clean Neovim で確認。
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(arg[0], ":p")))
vim.opt.rtp:prepend(root)
local dir = vim.fn.tempname()
vim.env.XDG_CACHE_HOME = dir .. "/cache"
vim.fn.mkdir(dir .. "/a/docs", "p")
vim.fn.mkdir(dir .. "/b/docs", "p")
local function write(path, lines)
  vim.fn.writefile(lines or { "flowchart LR", "  A --> B" }, path)
end
local original = { system = vim.system, executable = vim.fn.executable, notify = vim.notify, open = vim.ui.open,
  tempname = vim.fn.tempname }
local ok, err = pcall(function()
  local jobs, notices, opened = {}, {}, {}
  vim.system = function(cmd, opts, callback)
    jobs[#jobs + 1] = { cmd = cmd, callback = callback }
  end
  vim.fn.executable = function(cmd)
    return (cmd == "mmdc" or cmd == "golangci-lint") and 1 or 0
  end
  vim.notify = function(msg) notices[#notices + 1] = msg end
  vim.ui.open = function(path) opened[#opened + 1] = path end
  local preview = require("workflow.preview")
  for _, worktree in ipairs({ "a", "b", "a" }) do
    local file = dir .. "/" .. worktree .. "/docs/flow.mmd"
    write(file)
    vim.cmd.edit(vim.fn.fnameescape(file))
    vim.bo.filetype = "mermaid"
    preview.open()
  end
  assert(#jobs == 3 and jobs[1].cmd[5] ~= jobs[2].cmd[5] and jobs[1].cmd[5] ~= jobs[3].cmd[5],
    "parallel Mermaid outputs must be independent")
  jobs[2].callback({ code = 0 })
  jobs[1].callback({ code = 0 })
  assert(vim.wait(1000, function() return #opened == 2 end))
  assert(opened[1] == jobs[2].cmd[5] and opened[2] == jobs[1].cmd[5], "wrong preview opened")
  vim.api.nvim_create_autocmd("BufWritePre", { buffer = 0, once = true, callback = function() error("fixture cannot save") end })
  preview.open()
  assert(#jobs == 3 and notices[#notices]:find("保存できない", 1, true), "rendered stale file after save failure")
  vim.fn.executable = function() return 0 end
  preview.open()
  assert(#jobs == 3 and notices[#notices]:find("mmdc", 1, true), "missing tool was not handled")
  vim.fn.executable = function() return 1 end
  for _, process in ipairs({ "process-a", "process-b" }) do
    vim.fn.tempname = function() return "/tmp/" .. process .. "/0" end
    preview.open()
  end
  vim.fn.tempname = original.tempname
  assert(jobs[4].cmd[5] ~= jobs[5].cmd[5], "separate Neovim processes reused a Mermaid output")

  -- 最近の HTML 資料と Codex 規約も同じ入口から辿る。
  write(dir .. "/a/docs/recent.html", { "<!doctype html><title>Recent</title>" })
  vim.fn.mkdir(dir .. "/a/.agents/skills/example", "p")
  write(dir .. "/a/.agents/skills/example/SKILL.md", { "# Example" })
  package.loaded["workflow.project"] = { root = function() return dir .. "/a" end, find_first = function() end }
  local picked, grepped
  _G.Snacks = { picker = {
    pick = function(opts) picked = opts.items end,
    grep = function(opts) grepped = opts.glob end,
  } }
  require("workflow.spec").pick()
  local found = {}
  for _, item in ipairs(picked) do found[item.text] = true end
  assert(found["docs/recent.html"] and found["docs/flow.mmd"] and found[".agents/skills/example/SKILL.md"], "missing recent spec format")
  require("workflow.spec").grep()
  assert(vim.tbl_contains(grepped, "*.html") and vim.tbl_contains(grepped, "*.mmd"))

  -- nvim-lint の識別名ではなく実際の cmd (関数形式を含む) を検査する。
  vim.fn.executable = function(cmd) return cmd == "golangci-lint" and 1 or 0 end
  local calls = {}
  local lint = { linters = {}, try_lint = function(names) calls[#calls + 1] = names end }
  package.loaded.lint = lint
  require("plugins.linting")[1].config()
  vim.bo.filetype = "go"
  for _, def in ipairs({ { cmd = "golangci-lint" }, { cmd = function() return "golangci-lint" end },
    function() return { cmd = "golangci-lint" } end }) do
    lint.linters.golangcilint = def
    vim.api.nvim_exec_autocmds("InsertLeave", { group = "Linting" })
  end
  assert(#calls == 3 and calls[1][1] == "golangcilint", "installed Go linter was skipped")
  for _, def in ipairs({ { cmd = "missing-tool" }, function() error("unavailable") end }) do
    lint.linters.golangcilint = def
    vim.api.nvim_exec_autocmds("InsertLeave", { group = "Linting" })
  end
  assert(#calls == 3, "missing external tool was launched")
end)
vim.system, vim.fn.executable, vim.notify, vim.ui.open = original.system, original.executable, original.notify, original.open
vim.fn.tempname = original.tempname
vim.fn.delete(dir, "rf")
if not ok then io.stderr:write(tostring(err) .. "\n"); os.exit(1) end
io.write("editor: parallel Mermaid / save failure / missing tools / HTML specs / Go lint passed\n")
