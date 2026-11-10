-- ==========================================================
-- agents: 並走する Claude の状態を見失わない (R-14)
--   Claude Code の hook (scripts/claude-hooks.json → scripts/agent-signal.sh) が
--   親 Neovim の M.signal() を呼び、セッションごとの状態を更新する。
--     waiting 判断待ち (許可・質問)   done 完了・未読   working 作業中   idle 待機
--   表示: ステータスライン / タブライン / :ClaudeSessions / 通知
--   操作: <leader>aw で「自分を待っているセッション」へ跳ぶ
-- hook が届かない環境では何も表示しないだけで、Claude の起動・操作には影響しない。
-- ==========================================================

local project = require("workflow.project")

local M = {}

M.STATES = {
  waiting = { icon = "!", label = "判断待ち", order = 1, hl = "DiagnosticWarn" },
  done = { icon = "✓", label = "完了・未読", order = 2, hl = "DiagnosticOk" },
  working = { icon = "▶", label = "作業中", order = 3, hl = "DiagnosticInfo" },
  idle = { icon = "·", label = "待機", order = 4, hl = "Comment" },
}

-- 状態を変えない通知 (知らせるだけ、または完了後の入力待ち)
local INFORMATIONAL = { auth_success = true, agent_completed = true }

---@class workflow.AgentSession
---@field slot string "main" または :ClaudeNew の番号
---@field state "waiting"|"done"|"working"|"idle"
---@field since integer 状態が変わった時刻 (os.time)
---@field cwd? string
---@field session_id? string
---@field message? string 直近の通知・最終発言の 1 行目
---@field buf? integer

---@type table<string, workflow.AgentSession>
M.sessions = {}

local focused = true
local autocmds_ready = false

---@param title string
---@param body string
--- Neovim にフォーカスが無いとき、macOS の通知センターへ出す。vim.g.agent_os_notify = false で止める。
function M.os_notify(title, body)
  if vim.g.agent_os_notify == false or vim.fn.executable("osascript") == 0 then
    return
  end
  pcall(vim.system, {
    "osascript", "-e", "on run argv",
    "-e", "display notification (item 2 of argv) with title (item 1 of argv)",
    "-e", "end run", title, body,
  }, { detach = true })
end

---@param text any
---@return string|nil
local function first_line(text)
  if type(text) ~= "string" then
    return nil
  end
  local line = vim.trim(text):match("^[^\r\n]*") or ""
  if vim.fn.strchars(line) > 120 then
    line = vim.fn.strcharpart(line, 0, 117) .. "…"
  end
  return line ~= "" and line or nil
end

---@param session workflow.AgentSession
---@return string
function M.label(session)
  local name = session.slot == "main" and "main" or ("#" .. session.slot)
  return session.cwd and (name .. " " .. project.label(session.cwd)) or name
end

--- セッションのターミナルバッファ。起動コマンドに埋めた NVIM_CLAUDE_SLOT から探す。
---@param slot string
---@return integer|nil
function M.buf(slot)
  local session = M.sessions[slot]
  if session and session.buf and vim.api.nvim_buf_is_valid(session.buf) then
    return session.buf
  end
  local needle = "NVIM_CLAUDE_SLOT=" .. slot .. " "
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
      local term = vim.b[buf].snacks_terminal
      local cmd = term and (type(term.cmd) == "table" and table.concat(term.cmd, " ") or term.cmd) or ""
      if vim.b[buf].claude_slot == slot
        or vim.api.nvim_buf_get_name(buf):find(needle, 1, true)
        or (type(cmd) == "string" and cmd:find(needle, 1, true)) then
        if session then
          session.buf = buf
        end
        return buf
      end
    end
  end
  return nil
end

--- そのセッションの画面を今まさに見ているか (現在のタブに表示され、Neovim にフォーカスがある)
---@param slot string
---@return boolean
local function watching(slot)
  local buf = M.buf(slot)
  if not focused or not buf then
    return false
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      return true
    end
  end
  return false
end

local function refresh()
  pcall(vim.cmd, "redrawstatus")
  pcall(vim.cmd, "redrawtabline")
end

--- 完了したセッションの画面に入ったら「既読」にする
local function mark_seen()
  if vim.bo.buftype ~= "terminal" then
    return
  end
  local current = vim.api.nvim_get_current_buf()
  for slot, session in pairs(M.sessions) do
    if session.state == "done" and M.buf(slot) == current then
      session.state, session.since = "idle", os.time()
      refresh()
    end
  end
end

local function ensure_autocmds()
  if autocmds_ready then
    return
  end
  autocmds_ready = true
  local group = vim.api.nvim_create_augroup("WorkflowAgents", { clear = true })
  vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = function() focused = false end })
  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      focused = true
      mark_seen()
    end,
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermEnter" }, { group = group, callback = mark_seen })
  -- Claude を閉じたら hook (SessionEnd) が届かなくても一覧から消す
  vim.api.nvim_create_autocmd("TermClose", {
    group = group,
    callback = function(args)
      for slot, session in pairs(M.sessions) do
        if session.buf == args.buf then
          M.sessions[slot] = nil
          refresh()
        end
      end
    end,
  })
end

---@param payload? string Base64 の hook 入力 (JSON)。壊れていれば空として扱う
---@return table
local function decode(payload)
  if type(payload) ~= "string" or payload == "" then
    return {}
  end
  local ok, json = pcall(vim.base64.decode, payload)
  if not ok then
    return {}
  end
  local decoded_ok, data = pcall(vim.json.decode, json, { luanil = { object = true, array = true } })
  return decoded_ok and type(data) == "table" and data or {}
end

---@param session workflow.AgentSession
---@param state string
---@param message? string
local function announce(session, state, message)
  local info = M.STATES[state]
  local body = M.label(session) .. ": " .. info.label .. (message and (" — " .. message) or "")
  if not watching(session.slot) then
    vim.notify(body, state == "waiting" and vim.log.levels.WARN or vim.log.levels.INFO,
      { title = "Claude", id = "agent-" .. session.slot })
  end
  if not focused then
    M.os_notify("Claude " .. info.label, body)
  end
end

---@param slot string
---@param event string
---@param payload? string
local function apply(slot, event, payload)
  ensure_autocmds()
  local data = decode(payload)
  if event == "SessionEnd" then
    M.sessions[slot] = nil
    refresh()
    return
  end
  local session = M.sessions[slot] or { slot = slot, state = "idle", since = os.time() }
  M.sessions[slot] = session
  session.cwd = type(data.cwd) == "string" and data.cwd or session.cwd
  session.session_id = type(data.session_id) == "string" and data.session_id or session.session_id
  M.buf(slot)

  local previous, state, message = session.state, session.state, nil
  if event == "UserPromptSubmit" or event == "PostToolUse" then
    state = "working"
  elseif event == "Stop" then
    state, message = "done", first_line(data.last_assistant_message)
  elseif event == "Notification" then
    local kind = data.notification_type
    if kind == "idle_prompt" then
      state = previous == "working" and "done" or previous
    elseif not INFORMATIONAL[kind] then
      state, message = "waiting", first_line(data.message)
    end
  end

  if state ~= previous then
    session.since = os.time()
    session.message = message
    if state == "waiting" or state == "done" then
      announce(session, state, message)
    end
    -- 見ている画面で終わったものは未読にしない
    if state == "done" and watching(slot) then
      state = "idle"
    end
    session.state = state
  elseif message then
    session.message = message
  end
  refresh()
end

--- hook から `nvim --server $NVIM --remote-expr` で呼ばれる。失敗しても Claude 側へ波及させない。
---@param slot string
---@param event string
---@param payload? string
---@return string
function M.signal(slot, event, payload)
  local ok, err = pcall(apply, tostring(slot), tostring(event), payload)
  return ok and "" or tostring(err)
end

--- 自分を待っている順 (判断待ち → 完了・未読 → 作業中 → 待機)。同じ状態は古い順
---@return workflow.AgentSession[]
function M.list()
  local items = vim.tbl_values(M.sessions)
  table.sort(items, function(a, b)
    local oa, ob = M.STATES[a.state].order, M.STATES[b.state].order
    if oa ~= ob then
      return oa < ob
    end
    if a.since ~= b.since then
      return a.since < b.since
    end
    return a.slot < b.slot
  end)
  return items
end

--- ステータスライン用。例: "󰚩 !1 ✓1 ▶2"
---@return string
function M.statusline()
  local counts = {}
  for _, session in pairs(M.sessions) do
    counts[session.state] = (counts[session.state] or 0) + 1
  end
  local parts = {}
  for _, state in ipairs({ "waiting", "done", "working", "idle" }) do
    if counts[state] then
      parts[#parts + 1] = M.STATES[state].icon .. counts[state]
    end
  end
  return #parts > 0 and ("\u{F06A9} " .. table.concat(parts, " ")) or ""
end

--- ステータスラインの色に使う、最も優先度の高い状態
---@return string|nil
function M.top_state()
  local first = M.list()[1]
  return first and first.state or nil
end

--- タブライン用。その cwd で人を待っているセッションがあれば印を返す
---@param cwd string
---@return string
function M.attention(cwd)
  local best
  for _, session in pairs(M.sessions) do
    local here = session.cwd and (session.cwd == cwd or vim.startswith(session.cwd, cwd .. "/"))
    if here and (session.state == "waiting" or session.state == "done") then
      if not best or M.STATES[session.state].order < M.STATES[best].order then
        best = session.state
      end
    end
  end
  return best and (M.STATES[best].icon .. " ") or ""
end

--- セッションの画面へ移る (別タブに出ていればそのタブへ。隠れていれば開く)
---@param slot string
---@param quiet? boolean 見つからなくても通知しない
---@return boolean
function M.focus(slot, quiet)
  local buf = M.buf(slot)
  if not buf then
    if not quiet then
      vim.notify("Claude " .. slot .. " の画面が見つかりません", vim.log.levels.WARN)
    end
    return false
  end
  local wins = vim.fn.win_findbuf(buf)
  if #wins > 0 then
    vim.api.nvim_set_current_win(wins[1])
  else
    local shown = false
    if _G.Snacks and Snacks.terminal then
      for _, term in ipairs(Snacks.terminal.list()) do
        if term.buf == buf then
          term:show()
          term:focus()
          shown = true
        end
      end
    end
    if not shown then
      vim.cmd("botright vsplit")
      vim.api.nvim_win_set_buf(0, buf)
    end
  end
  mark_seen()
  if vim.bo.buftype == "terminal" then
    vim.cmd.startinsert()
  end
  return true
end

--- 自分を待っているセッション (判断待ち → 完了・未読) へ跳ぶ
function M.next()
  for _, session in ipairs(M.list()) do
    -- 画面を特定できないセッション (hook だけ届いた等) は飛ばして次を探す
    if (session.state == "waiting" or session.state == "done") and M.focus(session.slot, true) then
      return true
    end
  end
  vim.notify("判断待ち・未読の Claude はありません", vim.log.levels.INFO)
  return false
end

--- 経過時間を短く表示する
---@param since integer
---@return string
function M.age(since)
  local seconds = math.max(0, os.time() - since)
  if seconds < 60 then
    return seconds .. "s"
  elseif seconds < 3600 then
    return math.floor(seconds / 60) .. "m"
  end
  return math.floor(seconds / 3600) .. "h"
end

return M
