-- ==========================================================
-- claude: Neovim の中で Claude Code を複数並走させる (R-09)
-- メインの 1 本は claudecode.nvim (<leader>ac, IDE 連携・diff 受理)
-- 追加のセッションはここで立てる (別タスク・別 worktree 用)
-- ==========================================================

local project = require("workflow.project")

local M = {}

-- TMUX を外す: Neovim の :terminal の中なのに tmux 配下と判定され、コピー時の OSC 52 を tmux 用の
--   DCS（ESC Ptmux;）で包んで送ってくる。libvterm はそれを解釈できず、入力欄に「52;c;<base64>」が出る。
--   素の OSC 52 なら Neovim が受けてクリップボードへ書く（:h terminal-osc52）
-- 電源接続中は Claude が動いている間スリープさせない（caffeinate -s はバッテリー時は効かない。蓋を閉じたら止まる）
M.cmd = "env -u TMUX -u TMUX_PANE "
  .. (vim.fn.executable("caffeinate") == 1 and "caffeinate -s " or "")
  .. "claude --dangerously-skip-permissions"

local WIN = { position = "right", width = 0.4 }
local slot = 0

---@param term table snacks terminal
---@return boolean
local function is_claude(term)
  local cmd = vim.b[term.buf].snacks_terminal and vim.b[term.buf].snacks_terminal.cmd
  cmd = type(cmd) == "table" and table.concat(cmd, " ") or cmd
  return type(cmd) == "string" and cmd:find("claude", 1, true) ~= nil
end

--- 新しい Claude セッションを現在のタブの cwd で起動する
function M.new()
  if vim.fn.executable("claude") == 0 then
    vim.notify("claude コマンドが見つかりません", vim.log.levels.ERROR)
    return
  end
  slot = slot + 1
  -- env を変えると snacks は別のターミナルとして扱う
  local label = "#" .. slot .. " " .. project.label(project.cwd())
  local term = Snacks.terminal.open(M.cmd, {
    cwd = project.cwd(),
    env = { NVIM_CLAUDE_SLOT = tostring(slot) },
    win = vim.tbl_extend("force", WIN, { title = " Claude " .. label .. " " }),
  })
  if term and term.buf then
    vim.b[term.buf].claude_label = label
  end
end

--- 起動中の Claude セッションを一覧して切り替える
function M.pick()
  local terms = vim.tbl_filter(is_claude, Snacks.terminal.list())
  if #terms == 0 then
    vim.notify("起動中の Claude はありません (<leader>ac / <leader>an で起動)", vim.log.levels.INFO)
    return
  end
  Snacks.picker.pick({
    title = "Claude sessions",
    items = vim.tbl_map(function(term)
      return {
        text = vim.b[term.buf].claude_label or "main (claudecode)",
        buf = term.buf,
        term = term,
      }
    end, terms),
    format = "text",
    preview = function(ctx)
      ctx.preview:set_lines(vim.api.nvim_buf_get_lines(ctx.item.buf, -40, -1, false))
    end,
    confirm = function(picker, item)
      picker:close()
      item.term:show()
      item.term:focus()
    end,
  })
end

return M
