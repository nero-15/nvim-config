-- ==========================================================
-- check / verify: 日常の影響範囲検証と節目の全体検証を分けて回す (R-06)
-- 結果は quickfix に流し、]q で赤に直接飛べるようにする
-- 証拠 (R-15): どの内容を検証したかを tree ID で記録し、ログをファイルに残す。
--   赤い結果は <leader>av で Claude へ渡せる
-- ==========================================================

local project = require("workflow.project")

local M = {}
local MODES = { check = "Check", verify = "Verify" }

-- go / golangci-lint / tsc / vitest / playwright / 一般的な file:line:col 形式
local ERRORFORMAT = table.concat({
  "%f:%l:%c: %m",
  "%f(%l\\,%c): %m",
  "%f:%l:%c - %m",
  "%\\s%#❯ %f:%l:%c",
  "%\\s%#at %f:%l:%c",
  "%f:%l: %m",
}, ",")

local state = { running = false, output = {}, run = nil }
local sequence = 0

---@param path string
---@return table|nil
local function read_json(path)
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local decoded_ok, data = pcall(vim.json.decode, table.concat(content, "\n"))
  return decoded_ok and type(data) == "table" and data or nil
end

--- パッケージマネージャーを lockfile から判定
---@param root string
---@return string
local function node_runner(root)
  if vim.uv.fs_stat(root .. "/pnpm-lock.yaml") then
    return "pnpm"
  elseif vim.uv.fs_stat(root .. "/yarn.lock") then
    return "yarn"
  elseif vim.uv.fs_stat(root .. "/bun.lock") or vim.uv.fs_stat(root .. "/bun.lockb") then
    return "bun"
  end
  return "npm"
end

--- 指定した検証だけを探す。check が無くても verify へは代用しない。
---@param root string
---@param mode? "check"|"verify"
---@return string[]|nil
function M.detect(root, mode)
  mode = mode or "verify"
  if not MODES[mode] then return nil end
  local pkg = read_json(root .. "/package.json")
  if pkg and type(pkg.scripts) == "table" and type(pkg.scripts[mode]) == "string" then
    return { node_runner(root), "run", mode }
  end
  local makefile = root .. "/Makefile"
  if vim.uv.fs_stat(makefile) and vim.fn.match(vim.fn.readfile(makefile), "^" .. mode .. ":") >= 0 then
    return { "make", mode }
  end
  if vim.uv.fs_stat(root .. "/scripts/" .. mode .. ".sh") then
    return { "bash", "scripts/" .. mode .. ".sh" }
  end
  return nil
end

--- Parse in the originating directory without changing the user's cwd scope.
--- This also resolves diagnostics for deleted/nonexistent files correctly.
local function quickfix_items(run)
  local cwd = vim.fn.getcwd()
  local restore = vim.fn.haslocaldir() == 1 and "lcd"
    or (vim.fn.haslocaldir(-1, 0) == 1 and "tcd" or "cd")
  local ok, result = pcall(function()
    vim.cmd("noautocmd lcd " .. vim.fn.fnameescape(run.root))
    return vim.fn.getqflist({ lines = state.output, efm = ERRORFORMAT }).items
  end)
  vim.cmd("noautocmd " .. restore .. " " .. vim.fn.fnameescape(cwd))
  if not ok then
    return {}, tostring(result)
  end
  return result
end

local function head(root)
  if vim.fn.executable("git") == 0 then return nil end
  local ok, result = pcall(project.git, { "rev-parse", "--verify", "HEAD" }, root)
  return ok and result and result[1] or nil
end

local TREE_ID = project.CONFIG .. "/scripts/tree-id.sh"

--- 作業木の内容の ID (未コミット・未追跡を含む)。git の外や失敗時は nil を渡す
---@param root string
---@param callback fun(tree: string|nil)
local function tree_id(root, callback)
  if vim.fn.executable("git") == 0 or not vim.uv.fs_stat(TREE_ID) then
    return callback(nil)
  end
  local ok = pcall(vim.system, { "sh", TREE_ID, root }, { text = true }, function(result)
    local tree = result.code == 0 and vim.trim(result.stdout or "") or ""
    vim.schedule(function() callback(tree:match("^%x+$") and tree or nil) end)
  end)
  if not ok then callback(nil) end
end

---@param run table
---@return string[]
local function log_lines(run)
  local lines = {
    "mode: " .. run.mode,
    "root: " .. run.root,
    "command: " .. table.concat(run.command, " "),
    "started: " .. run.started_at,
    "finished: " .. (run.finished_at or "実行中"),
    "HEAD (start): " .. (run.started_head or "取得なし"),
    "HEAD (finish): " .. (run.finished_head or "取得なし"),
    "tree (start): " .. (run.started_tree or "取得なし"),
    "tree (finish): " .. (run.finished_tree or "取得なし"),
    "exit: " .. (run.exit_code ~= nil and tostring(run.exit_code) or "実行中"),
    run.note, "", "--- output ---",
  }
  vim.list_extend(lines, state.output)
  return lines
end

--- 実行記録をファイルに残す (エージェントへ渡す・後から読む)。プロジェクトの外に置き、作業木を汚さない
---@param run table
local function save_log(run)
  local dir = vim.fn.stdpath("state") .. "/verify"
  local path = string.format("%s/%s-%s.log", dir, vim.fn.sha256(run.root):sub(1, 12), run.mode)
  local ok = pcall(function()
    vim.fn.mkdir(dir, "p")
    vim.fn.writefile(log_lines(run), path)
  end)
  run.log_path = ok and path or nil
end

local function on_done(code, elapsed, run)
  state.running = false
  run.exit_code, run.elapsed = code, elapsed
  run.finished_at = os.date("!%Y-%m-%dT%H:%M:%SZ")
  run.finished_head = head(run.root)
  save_log(run)
  local title = MODES[run.mode] .. " [" .. run.root .. "]: " .. table.concat(run.command, " ")
  local items, parse_error = quickfix_items(run)
  vim.fn.setqflist({}, " ", { title = title, items = items, context = vim.deepcopy(run) })
  local valid = vim.tbl_filter(function(item) return item.valid == 1 end, items)
  local summary = string.format("%.1fs / quickfix %d 件", elapsed, #valid)
  local changed = run.started_head ~= run.finished_head or run.started_tree ~= run.finished_tree
  if parse_error then
    vim.notify(run.mode .. " の診断を解決できませんでした: " .. parse_error, vim.log.levels.ERROR)
    M.show_log()
  elseif code == 0 and not changed then
    vim.notify(run.mode .. " green ✓ " .. summary, vim.log.levels.INFO, { id = "verify", title = title })
  elseif code == 0 then
    vim.notify(run.mode .. " exit 0 / 実行中に HEAD か作業木の内容が変わりました。再検証してください", vim.log.levels.WARN,
      { id = "verify", title = title })
  else
    vim.notify(run.mode .. " red ✗ (exit " .. code .. ") " .. summary, vim.log.levels.ERROR, { id = "verify", title = title })
    if #valid > 0 then vim.cmd("botright copen") else M.show_log() end
  end
end

--- 指定した検証を非同期実行。引数なしは既存の verify と同じ。
---@param mode? "check"|"verify"
function M.run(mode)
  mode = mode or "verify"
  if not MODES[mode] then
    vim.notify("検証モードは check / verify を指定してください", vim.log.levels.WARN)
    return
  end
  if state.running then
    vim.notify(state.run.mode .. " は実行中です", vim.log.levels.WARN)
    return
  end
  local root = project.root()
  local cmd = M.detect(root, mode)
  if not cmd then
    vim.notify(string.format("%s コマンドが見つかりません (package.json の scripts.%s / Makefile の %s: / scripts/%s.sh)",
      mode, mode, mode, mode),
      vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(cmd[1]) == 0 then
    vim.notify(cmd[1] .. " が見つかりません", vim.log.levels.ERROR)
    return
  end

  local saved, save_error = pcall(vim.cmd, "silent wall")
  if not saved then
    vim.notify("保存に失敗したため " .. mode .. " を中止しました: " .. tostring(save_error), vim.log.levels.ERROR)
    return
  end
  sequence = sequence + 1
  local run = {
    id = sequence, mode = mode, root = root, command = vim.deepcopy(cmd),
    started_at = os.date("!%Y-%m-%dT%H:%M:%SZ"), started_head = head(root),
    note = "tree は作業木の内容 (未コミット・未追跡を含み、ignore を除く) の ID。結果は実行時点の記録で、現在のファイルの保証ではありません。",
  }
  state.running, state.output, state.run = true, {}, run
  vim.fn.setqflist({}, " ", {
    title = MODES[mode] .. " [" .. root .. "]: 実行中", items = {}, context = vim.deepcopy(run),
  })
  vim.notify("実行中… " .. table.concat(cmd, " "), vim.log.levels.INFO, { id = "verify", title = MODES[mode] })

  local function launch()
    local started = vim.uv.hrtime()
    local tails = { stdout = "", stderr = "" }
    local function collect(stream)
      return function(err, data)
        if err then run.stream_error = tostring(err) end
        if not data then return end
        local parts = vim.split(tails[stream] .. data, "\n", { plain = true })
        tails[stream] = table.remove(parts)
        for _, line in ipairs(parts) do
          state.output[#state.output + 1] = line:gsub("\r$", "")
        end
      end
    end
    local ok, err = pcall(vim.system, cmd, {
      cwd = root, text = true, stdout = collect("stdout"), stderr = collect("stderr"),
    }, function(result)
      local elapsed = (vim.uv.hrtime() - started) / 1e9
      vim.schedule(function()
        for _, stream in ipairs({ "stdout", "stderr" }) do
          if tails[stream] ~= "" then state.output[#state.output + 1] = tails[stream]:gsub("\r$", "") end
        end
        if run.stream_error then state.output[#state.output + 1] = "Output read error: " .. run.stream_error end
        tree_id(root, function(tree)
          run.finished_tree = tree
          on_done(run.stream_error and -1 or result.code, elapsed, run)
        end)
      end)
    end)
    if not ok then
      state.running = false
      run.exit_code, run.finished_at = -1, os.date("!%Y-%m-%dT%H:%M:%SZ")
      state.output = { mode .. " を起動できませんでした: " .. tostring(err) }
      vim.fn.setqflist({}, " ", {
        title = MODES[mode] .. " [" .. root .. "]: 起動失敗", items = {}, context = vim.deepcopy(run),
      })
      vim.notify(state.output[1], vim.log.levels.ERROR)
    end
  end
  -- 開始時の内容を控えてから実行する (実行中にエージェントが書き換えたら終了時の ID と食い違う)
  tree_id(root, function(tree)
    run.started_tree = tree
    launch()
  end)
end

--- 直前の check / verify の実行記録をスクラッチバッファで開く
function M.show_log()
  local run = state.run
  if not run then
    vim.notify("check / verify の実行記録はまだありません", vim.log.levels.INFO)
    return
  end
  local lines = log_lines(run)
  -- Reuse the same buffer so repeated :VerifyLog calls cannot hit E95.
  local name = "verify://run-" .. run.id
  local buf = vim.fn.bufnr(name)
  if buf == -1 then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(buf, name)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close verify log" })
  end
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local win = vim.fn.bufwinid(buf)
  if win ~= -1 then
    vim.api.nvim_set_current_win(win)
  else
    vim.cmd("botright split")
    vim.api.nvim_win_set_buf(0, buf)
  end
end

--- 直前の赤い結果を、メインの Claude の入力欄へ渡す (送信はしない。人が方針を足してから Enter)
function M.send_to_claude()
  local run = state.run
  if not run or run.exit_code == nil then
    vim.notify("渡せる check / verify の結果がありません (実行中、または未実行)", vim.log.levels.INFO)
    return
  end
  if run.exit_code == 0 then
    vim.notify("直前の " .. run.mode .. " は exit 0 です。渡す失敗はありません", vim.log.levels.INFO)
    return
  end
  if not run.log_path then
    vim.notify("実行ログを保存できなかったため渡せません。<leader>vl で確認してください", vim.log.levels.WARN)
    return
  end
  local command = table.concat(run.command, " ")
  require("workflow.claude").insert(string.format(
    "直前の %s (`%s`, root: %s) が exit %d で失敗しました。ログ @%s を読んで原因を特定し、修正して、同じコマンドが green になるまで確認してください。",
    run.mode, command, run.root, run.exit_code, run.log_path))
end

return M
