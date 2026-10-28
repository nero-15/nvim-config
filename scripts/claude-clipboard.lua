-- R-09: Claude 2.1.287 の copy-on-select 出力を模擬し、内蔵端末での文字漏れを検査する。
-- 実 Claude / OS のクリップボード / 稼働中の tmux は使用しない。
-- nvim --clean --headless -l scripts/claude-clipboard.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(arg[0], ":p")))
vim.opt.rtp:prepend(root)

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local text = "選択した日本語をコピーする。" .. string.rep("長い選択範囲。", 100)
local encoded = vim.base64.encode(text)
local copies = {}
vim.g.clipboard = {
  name = "clipboard regression fixture",
  copy = {
    ["+"] = function(lines) copies[#copies + 1] = table.concat(lines, "\n") end,
    ["*"] = function(lines) copies[#copies + 1] = table.concat(lines, "\n") end,
  },
  paste = {
    ["+"] = function() return { {}, "v" } end,
    ["*"] = function() return { {}, "v" } end,
  },
}

vim.fn.writefile({
  "#!/bin/sh",
  'printf "%s\\n" "$@" > "$CLAUDE_PROBE_ARGS"',
  'printf "%s" "$CLAUDE_CODE_SSE_PORT" > "$CLAUDE_PROBE_IDE"',
  -- Claude は通常 OSC 52 に加え、TMUX があれば DCS ラッパーも出す。
  'printf "\\033]52;c;%s\\007" "$CLAUDE_PROBE_B64"',
  'if [ -n "${TMUX:-}" ]; then',
  '  printf "\\033Ptmux;\\033\\033]52;c;%s\\007\\033\\\\" "$CLAUDE_PROBE_B64"',
  "fi",
}, dir .. "/claude")
assert(vim.fn.setfperm(dir .. "/claude", "rwx------") == 1)
-- caffeinate の引数を維持しつつ、テストでは実機の電源状態を変更しない。
vim.fn.writefile({ "#!/bin/sh", '[ "$1" = -s ] || exit 1', "shift", 'exec "$@"' }, dir .. "/caffeinate")
assert(vim.fn.setfperm(dir .. "/caffeinate", "rwx------") == 1)

local function check(cmd, tmux)
  copies = {}
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  local code
  local job = vim.fn.jobstart({ "/bin/sh", "-c", cmd .. " --resume 'session with spaces'" }, {
    term = true,
    on_exit = function(_, status) code = status end,
    env = {
      PATH = dir .. ":" .. vim.env.PATH,
      TMUX = tmux,
      TMUX_PANE = tmux ~= "" and "%99" or "",
      CLAUDE_CODE_SSE_PORT = "12345",
      CLAUDE_PROBE_ARGS = dir .. "/args",
      CLAUDE_PROBE_IDE = dir .. "/ide",
      CLAUDE_PROBE_B64 = encoded,
    },
  })
  assert(job > 0, "fixture failed to start")
  local exited = vim.wait(5000, function() return code ~= nil end, 10)
  if not exited then vim.fn.jobstop(job) end
  assert(exited, "fixture timed out")
  assert(code == 0, "fixture failed: " .. tostring(code))
  local screen = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
  vim.api.nvim_buf_delete(buf, { force = true })
  assert(#copies == 1 and copies[1] == text, "clipboard text was not preserved")
  assert(not screen:find("52;c;", 1, true) and not screen:find(encoded:sub(1, 32), 1, true),
    "clipboard control sequence / Base64 leaked into terminal display")
  assert(vim.deep_equal(vim.fn.readfile(dir .. "/args"), {
    "--dangerously-skip-permissions", "--resume", "session with spaces",
  }), "CLI arguments changed")
  assert(table.concat(vim.fn.readfile(dir .. "/ide")) == "12345", "IDE environment was lost")
end

local ok, err = pcall(function()
  for _, cmd in ipairs({ require("plugins.ai")[1].opts.terminal_cmd, require("workflow.claude").cmd }) do
    check(cmd, "/tmp/clipboard-fixture,123,0")
    check(cmd, "")
  end
end)
vim.fn.delete(dir, "rf")
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  os.exit(1)
end
io.write("claude clipboard: main / additional, with / without tmux passed\n")
