-- ==========================================================
-- claude: Neovim の中で Claude Code を複数並走させる (R-09, R-14)
-- メインの 1 本は claudecode.nvim (<leader>ac, IDE 連携・diff 受理)
-- 追加のセッションはここで立てる (別タスク・別 worktree 用)
-- 状態 (作業中 / 判断待ち / 完了) は hook 経由で lua/workflow/agents.lua に集まる
-- ==========================================================

local project = require("workflow.project")

local M = {}

local CONFIG = project.CONFIG
-- 判断待ちの目印を置く場所 (この Neovim だけが使う。scripts/agent-signal.sh)
local AGENT_DIR = vim.fn.stdpath("run") .. "/nvim-agents." .. vim.fn.getpid()

--- Claude の起動コマンド。
-- TMUX を外す: Neovim の :terminal の中なのに tmux 配下と判定され、コピー時の OSC 52 を tmux 用の
--   DCS（ESC Ptmux;）で包んで送ってくる。libvterm はそれを解釈できず、入力欄に「52;c;<base64>」が出る。
--   素の OSC 52 なら Neovim が受けてクリップボードへ書く（:h terminal-osc52）
-- NVIM_CLAUDE_SLOT / --settings: この Neovim から起動した Claude だけに状態通知の hook を足す。
--   ユーザーやプロジェクトの settings.json は書き換えない。
-- 電源接続中は Claude が動いている間スリープさせない（caffeinate -s はバッテリー時は効かない。蓋を閉じたら止まる）
---@param slot string|integer "main" または追加セッションの番号
---@param extra? string 追加の引数 (シェル向けにエスケープ済みのもの)
---@return string
function M.command(slot, extra)
  local esc = vim.fn.shellescape
  return table.concat({
    "env -u TMUX -u TMUX_PANE",
    "NVIM_CLAUDE_SLOT=" .. slot,
    "NVIM_AGENT_DIR=" .. esc(AGENT_DIR),
    "NVIM_AGENT_SIGNAL=" .. esc(CONFIG .. "/scripts/agent-signal.sh"),
    (vim.fn.executable("caffeinate") == 1 and "caffeinate -s " or "") .. "claude --dangerously-skip-permissions",
    "--settings " .. esc(CONFIG .. "/scripts/claude-hooks.json"),
    extra,
  }, " ")
end

M.cmd = M.command("main")

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
---@param opts? { worktree?: string } worktree を渡すと、その名前の git worktree を作って隔離して始める
function M.new(opts)
  opts = opts or {}
  if vim.fn.executable("claude") == 0 then
    vim.notify("claude コマンドが見つかりません", vim.log.levels.ERROR)
    return
  end
  local cwd, extra, suffix = project.cwd(), nil, ""
  if opts.worktree then
    if not opts.worktree:match("^[%w][%w._-]*$") then
      vim.notify("worktree 名は英数字と . _ - で指定してください: " .. opts.worktree, vim.log.levels.WARN)
      return
    end
    cwd = project.root()
    extra = "--worktree " .. vim.fn.shellescape(opts.worktree)
    suffix = ":" .. opts.worktree
  end
  slot = slot + 1
  local label = "#" .. slot .. " " .. project.label(cwd) .. suffix
  local term = Snacks.terminal.open(M.command(slot, extra), {
    cwd = cwd,
    win = vim.tbl_extend("force", WIN, { title = " Claude " .. label .. " " }),
  })
  if term and term.buf then
    vim.b[term.buf].claude_label = label
    vim.b[term.buf].claude_slot = tostring(slot)
  end
end

--- 名前を聞いて、新しい worktree で Claude を起動する (独立した仕事を隔離して並走させる)
---@param name? string
function M.new_worktree(name)
  if name and name ~= "" then
    M.new({ worktree = name })
    return
  end
  vim.ui.input({ prompt = "新しい worktree の名前: " }, function(input)
    if input and input ~= "" then
      M.new({ worktree = input })
    end
  end)
end

--- Claude のターミナルと状態を突き合わせた一覧 (自分を待っている順)
---@return table[]
function M.items()
  local agents = require("workflow.agents")
  local by_buf = {}
  for _, session in pairs(agents.sessions) do
    local buf = agents.buf(session.slot)
    if buf then
      by_buf[buf] = session
    end
  end
  local items = {}
  for _, term in ipairs(vim.tbl_filter(is_claude, Snacks.terminal.list())) do
    local session = by_buf[term.buf]
    local state = session and agents.STATES[session.state] or nil
    local name = vim.b[term.buf].claude_label or (session and agents.label(session)) or "main (claudecode)"
    table.insert(items, {
      text = name .. " " .. (state and state.label or "") .. " " .. (session and session.message or ""),
      name = name,
      buf = term.buf,
      term = term,
      session = session,
      state = state,
      cwd = session and session.cwd or nil,
      order = state and state.order or 9,
      since = session and session.since or 0,
    })
  end
  table.sort(items, function(a, b)
    if a.order ~= b.order then
      return a.order < b.order
    end
    return a.since < b.since
  end)
  return items
end

--- 起動中の Claude セッションを一覧して切り替える
function M.pick()
  local items = M.items()
  if #items == 0 then
    vim.notify("起動中の Claude はありません (<leader>ac / <leader>an で起動)", vim.log.levels.INFO)
    return
  end
  local agents = require("workflow.agents")
  local function in_cwd(action)
    return function(picker, item)
      if not item.cwd then
        vim.notify("このセッションの作業ディレクトリはまだ届いていません", vim.log.levels.INFO)
        return
      end
      picker:close()
      require("workflow.worktree")[action](item.cwd)
    end
  end
  Snacks.picker.pick({
    title = "Claude sessions  <CR> 開く / <C-t> その場所をタブで / <C-d> 差分レビュー",
    items = items,
    format = function(item)
      local state = item.state
      return {
        { (state and state.icon or " ") .. " ", state and state.hl or "Comment" },
        { item.name, "Normal" },
        { state and ("  " .. state.label .. " " .. agents.age(item.since)) or "", state and state.hl or "Comment" },
        { item.session and item.session.message and ("  " .. item.session.message) or "", "Comment" },
      }
    end,
    preview = function(ctx)
      ctx.preview:set_lines(vim.api.nvim_buf_get_lines(ctx.item.buf, -40, -1, false))
    end,
    confirm = function(picker, item)
      picker:close()
      item.term:show()
      item.term:focus()
    end,
    actions = { claude_tab = in_cwd("open"), claude_diff = in_cwd("diff") },
    win = {
      input = {
        keys = {
          ["<C-t>"] = { "claude_tab", mode = { "n", "i" } },
          ["<C-d>"] = { "claude_diff", mode = { "n", "i" } },
        },
      },
    },
    matcher = { sort_empty = false },
  })
end

--- メインの Claude の入力欄へ文章を入れる (送信はしない。人が読んで舵を切ってから Enter)
---@param text string
---@return boolean
function M.insert(text)
  local ok, terminal = pcall(require, "claudecode.terminal")
  if not ok or type(terminal.send_to_terminal) ~= "function" then
    vim.notify("claudecode.nvim を読み込めません", vim.log.levels.ERROR)
    return false
  end
  if not terminal.get_active_terminal_bufnr() then
    vim.notify("メインの Claude が起動していません (<leader>ac で開いてから再実行)", vim.log.levels.WARN)
    return false
  end
  return terminal.send_to_terminal(text, { submit = false, focus = true }) == true
end

return M
