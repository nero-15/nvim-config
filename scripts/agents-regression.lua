-- R-14: Claude の hook 通知 → 状態 → 表示・ジャンプ。実 Claude・OS 通知は使用しない。
-- nvim --clean --headless -l scripts/agents-regression.lua
local root = vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(arg[0], ":p")))
vim.opt.rtp:prepend(root)

local agents = require("workflow.agents")
local notes, os_notes = {}, {}
vim.notify = function(message, level) notes[#notes + 1] = { message = message, level = level } end
agents.os_notify = function(title, body) os_notes[#os_notes + 1] = title .. " / " .. body end

local function eq(actual, expected, message)
  assert(vim.deep_equal(actual, expected),
    (message or "") .. " " .. vim.inspect({ actual = actual, expected = expected }))
end
local function payload(data) return vim.base64.encode(vim.json.encode(data)) end
local function state(slot) return agents.sessions[slot] and agents.sessions[slot].state or nil end

local temp = vim.fn.tempname()
vim.fn.mkdir(temp, "p")

local ok, err = xpcall(function()
  -- ── 起動コマンドと hook 定義 ──
  local claude = require("workflow.claude")
  local cmd = claude.command("main")
  for _, part in ipairs({
    "env -u TMUX -u TMUX_PANE", "NVIM_CLAUDE_SLOT=main ", "NVIM_AGENT_SIGNAL='" .. root .. "/scripts/agent-signal.sh'",
    "claude --dangerously-skip-permissions", "--settings '" .. root .. "/scripts/claude-hooks.json'",
  }) do
    assert(cmd:find(part, 1, true), "command lacks: " .. part .. "\n" .. cmd)
  end
  eq(claude.cmd, cmd, "main command")
  assert(claude.command(3, "--worktree 'x'"):match("NVIM_CLAUDE_SLOT=3 .*%-%-worktree 'x'$"), "extra args / slot")

  local hooks = vim.json.decode(table.concat(vim.fn.readfile(root .. "/scripts/claude-hooks.json"), "\n")).hooks
  local events = vim.tbl_keys(hooks)
  table.sort(events)
  eq(events, { "Notification", "PostToolUse", "SessionEnd", "SessionStart", "Stop", "UserPromptSubmit" })
  for event, groups in pairs(hooks) do
    local hook = groups[1].hooks[1]
    eq(hook.type, "command")
    -- 環境変数が無い (Neovim 外で設定だけ読まれた) ときは何もしない
    eq(hook.command, 'if [ -n "$NVIM_AGENT_SIGNAL" ]; then sh "$NVIM_AGENT_SIGNAL" ' .. event .. "; fi")
    -- 終了時以外は Claude を待たせない
    eq(hook.async == true, event ~= "SessionEnd", event .. " async")
  end

  -- ── 状態遷移 ──
  eq(agents.statusline(), "", "no sessions")
  eq(agents.signal("main", "SessionStart", payload({ cwd = "/work/api", session_id = "s1" })), "")
  eq(state("main"), "idle")
  eq(agents.sessions.main.cwd, "/work/api")
  agents.signal("main", "UserPromptSubmit", payload({ cwd = "/work/api" }))
  eq(state("main"), "working")
  agents.signal("main", "Notification", payload({ notification_type = "permission_prompt", message = "Bash を実行してよいですか\n2 行目" }))
  eq(state("main"), "waiting")
  eq(agents.sessions.main.message, "Bash を実行してよいですか", "first line only")
  eq(notes[#notes].level, vim.log.levels.WARN)
  assert(notes[#notes].message:find("main api: 判断待ち — Bash", 1, true), notes[#notes].message)
  eq(#os_notes, 0, "focused Neovim must not raise OS notifications")
  agents.signal("main", "PostToolUse", "")
  eq(state("main"), "working", "tool result resumes work")
  -- 知らせるだけの通知・未知でない完了後の入力待ちは判断待ちにしない
  agents.signal("main", "Notification", payload({ notification_type = "auth_success" }))
  eq(state("main"), "working")
  agents.signal("main", "Notification", payload({ notification_type = "idle_prompt" }))
  eq(state("main"), "done", "idle prompt after work means the turn ended")
  agents.signal("main", "UserPromptSubmit", "")
  agents.signal("main", "Stop", payload({ last_assistant_message = string.rep("長", 200) }))
  eq(state("main"), "done")
  eq(vim.fn.strchars(agents.sessions.main.message), 118, "long message is shortened")
  -- 未知の通知種別は「人を呼んでいる」とみなす
  agents.signal("2", "Notification", payload({ cwd = "/work/web", notification_type = "something_new", message = "?" }))
  eq(state("2"), "waiting")
  -- 壊れた入力でも落ちない
  eq(agents.signal("3", "Stop", "%%%not-base64"), "")
  eq(agents.signal("3", "Stop", vim.base64.encode("{truncated")), "")
  eq(state("3"), "done")

  -- ── 並び・表示 ──
  agents.sessions["2"].since = agents.sessions["2"].since - 10
  agents.signal("4", "UserPromptSubmit", payload({ cwd = "/work/api/.claude/worktrees/fix-a" }))
  eq(vim.tbl_map(function(s) return s.slot end, agents.list())[1], "2", "waiting comes first")
  eq(agents.statusline(), "\u{F06A9} !1 ✓2 ▶1")
  eq(agents.top_state(), "waiting")
  eq(agents.attention("/work/web"), "! ")
  eq(agents.attention("/work/api"), "✓ ", "done session in this cwd")
  eq(agents.attention("/work/ap"), "", "prefix of a different directory")
  eq(agents.attention("/elsewhere"), "")
  eq(agents.label(agents.sessions["4"]), "#4 api:fix-a")
  vim.o.tabline = "%!v:lua.require'workflow.tabline'.render()"
  assert(type(require("workflow.tabline").render()) == "string")

  -- ── ジャンプと既読 ──
  local function terminal(slot)
    vim.cmd("enew")
    local job = vim.fn.jobstart({ "/bin/sh", "-c", "sleep 30" }, { term = true })
    assert(job > 0, "fixture terminal failed")
    local buf = vim.api.nvim_get_current_buf()
    vim.b[buf].claude_slot = slot
    return buf, job
  end
  local buf2, job2 = terminal("2")
  local buf_main, job_main = terminal("main")
  -- その画面に居た状態から離れると既読になる (:tabnew は元の画面で WinEnter を起こす)。未読へ戻して続ける
  vim.cmd("tabnew")
  eq(state("main"), "idle", "leaving the screen you were watching counts as read")
  agents.sessions.main.state = "done"
  eq(agents.buf("2"), buf2)
  assert(agents.next(), "next should find a waiting session")
  eq(vim.api.nvim_get_current_buf(), buf2, "waiting session wins over done")
  eq(state("2"), "waiting", "waiting stays until Claude resumes")
  agents.signal("2", "PostToolUse", "")
  -- 画面の無い slot 3 (完了) は飛ばして、開ける main へ行く
  assert(agents.next(), "next should find the unread session")
  eq(vim.api.nvim_get_current_buf(), buf_main)
  eq(state("main"), "idle", "entering a finished session marks it read")
  -- 見ている画面で終わったものは通知も未読もしない
  local before = #notes
  agents.signal("main", "UserPromptSubmit", "")
  agents.signal("main", "Stop", payload({ last_assistant_message = "done" }))
  eq(state("main"), "idle")
  eq(#notes, before, "no toast for the session on screen")
  -- フォーカスが無いときは OS 通知も出す
  vim.api.nvim_exec_autocmds("FocusLost", {})
  agents.signal("main", "UserPromptSubmit", "")
  agents.signal("main", "Stop", payload({ last_assistant_message = "終わりました" }))
  eq(state("main"), "done", "unfocused completion stays unread")
  assert(os_notes[#os_notes]:find("終わりました", 1, true), vim.inspect(os_notes))
  vim.api.nvim_exec_autocmds("FocusGained", {})
  eq(state("main"), "idle", "regaining focus on that screen marks it read")
  agents.signal("3", "SessionEnd", "")
  eq(state("3"), nil)
  -- ターミナルを閉じたら一覧から消える (SessionEnd が届かなくても)
  vim.fn.jobstop(job2)
  assert(vim.wait(3000, function() return state("2") == nil end, 20), "closed terminal remained listed")
  agents.sessions["3"], agents.sessions["4"] = nil, nil
  agents.sessions.main.state = "idle"
  notes = {}
  eq(agents.next(), false)
  assert(notes[1].message:find("ありません", 1, true))

  -- ── 実際の hook スクリプト → RPC (end to end) ──
  local server = vim.fn.serverstart(temp .. "/nvim.sock")
  local function hook(event, slot, input, extra_env)
    local env = vim.tbl_extend("force", { NVIM = server, NVIM_CLAUDE_SLOT = slot, NVIM_AGENT_DIR = temp .. "/agents" },
      extra_env or {})
    local done
    vim.system({ "sh", root .. "/scripts/agent-signal.sh", event }, { env = env, stdin = input, text = true },
      function(result) done = result end)
    assert(vim.wait(5000, function() return done ~= nil end, 10), "hook did not return: " .. event)
    eq(done.code, 0, event .. " exit")
    eq((done.stdout or "") .. (done.stderr or ""), "", event .. " must be silent")
  end
  hook("UserPromptSubmit", "7", vim.json.encode({ cwd = "/work/日本語 dir", session_id = "s7", prompt = "it's \"quoted\"" }))
  eq(state("7"), "working")
  eq(agents.sessions["7"].cwd, "/work/日本語 dir")
  agents.sessions["7"].state = "idle"
  hook("PostToolUse", "7", "{}")
  eq(state("7"), "idle", "tool results do not wake Neovim unless a prompt was pending")
  hook("Notification", "7", vim.json.encode({ notification_type = "permission_prompt", message = "許可?" }))
  eq(state("7"), "waiting")
  assert(vim.uv.fs_stat(temp .. "/agents/7.waiting"), "waiting marker missing")
  hook("PostToolUse", "7", string.rep("x", 200000))
  eq(state("7"), "working")
  assert(not vim.uv.fs_stat(temp .. "/agents/7.waiting"), "waiting marker was not cleared")
  hook("Stop", "7", '{"last_assistant_message":"' .. string.rep("あ", 40000) .. '"}')
  eq(state("7"), "done", "oversized input still reports the event")
  -- Stop hook に促されて作業を続けた場合、次のツール実行で作業中へ戻る
  hook("PostToolUse", "7", "{}")
  eq(state("7"), "working", "work continued after a stop must not stay 'done'")
  hook("UserPromptSubmit", "7", "{}")
  assert(not vim.uv.fs_stat(temp .. "/agents/7.waiting"), "a new prompt clears the marker")
  hook("SessionEnd", "7", "{}")
  eq(state("7"), nil)
  -- 不正な slot・Neovim の外では何もしない
  hook("Stop", "x'y", "{}")
  hook("Stop", "8", "{}", { NVIM = "" })
  hook("Stop", "8", "{}", { NVIM_AGENT_DIR = "" })
  agents.sessions["8"] = nil
  eq(state("8"), nil)
  eq(vim.tbl_count(agents.sessions), 1, "only main remains: " .. vim.inspect(vim.tbl_keys(agents.sessions)))
  vim.fn.jobstop(job_main)
end, debug.traceback)

vim.fn.delete(temp, "rf")
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cq!")
end
io.write("agents: command, hooks, states, attention, focus, hook RPC passed\n")
vim.cmd("qa!")
