-- ==========================================================
-- verify: 停止条件 (make verify / pnpm verify) をエディタから回す (R-06)
-- 結果は quickfix に流し、]q で赤に直接飛べるようにする
-- ==========================================================

local project = require("workflow.project")

local M = {}

-- go / golangci-lint / tsc / vitest / playwright / 一般的な file:line:col 形式
local ERRORFORMAT = table.concat({
  "%f:%l:%c: %m",
  "%f(%l\\,%c): %m",
  "%f:%l:%c - %m",
  "%\\s%#❯ %f:%l:%c",
  "%\\s%#at %f:%l:%c",
  "%f:%l: %m",
}, ",")

local state = { running = false, output = {}, cmd = nil }

---@param path string
---@return table|nil
local function read_json(path)
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  local decoded_ok, data = pcall(vim.json.decode, table.concat(content, "\n"))
  return decoded_ok and data or nil
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

--- プロジェクトの種類から verify コマンドを決める
---@param root string
---@return string[]|nil
function M.detect(root)
  local pkg = read_json(root .. "/package.json")
  if pkg and pkg.scripts and pkg.scripts.verify then
    return { node_runner(root), "run", "verify" }
  end
  local makefile = root .. "/Makefile"
  if vim.uv.fs_stat(makefile) and vim.fn.match(vim.fn.readfile(makefile), "^verify:") >= 0 then
    return { "make", "verify" }
  end
  if vim.uv.fs_stat(root .. "/scripts/verify.sh") then
    return { "bash", "scripts/verify.sh" }
  end
  return nil
end

---@param code integer
---@param elapsed number
---@param cmd string[]
local function on_done(code, elapsed, cmd)
  state.running = false
  local title = "Verify: " .. table.concat(cmd, " ")
  vim.fn.setqflist({}, " ", { title = title, lines = state.output, efm = ERRORFORMAT })
  local valid = vim.tbl_filter(function(item)
    return item.valid == 1
  end, vim.fn.getqflist())
  local summary = string.format("%.1fs / quickfix %d 件", elapsed, #valid)
  if code == 0 then
    vim.notify("green ✓ " .. summary, vim.log.levels.INFO, { id = "verify", title = title })
  else
    vim.notify("red ✗ (exit " .. code .. ") " .. summary, vim.log.levels.ERROR, { id = "verify", title = title })
    vim.cmd(#valid > 0 and "botright copen" or "VerifyLog")
  end
end

--- verify を非同期で実行する
function M.run()
  if state.running then
    vim.notify("verify は実行中です", vim.log.levels.WARN)
    return
  end
  local root = project.root()
  local cmd = M.detect(root)
  if not cmd then
    vim.notify("verify コマンドが見つかりません (package.json の scripts.verify / Makefile の verify: / scripts/verify.sh)",
      vim.log.levels.WARN)
    return
  end
  if vim.fn.executable(cmd[1]) == 0 then
    vim.notify(cmd[1] .. " が見つかりません", vim.log.levels.ERROR)
    return
  end

  vim.cmd("silent! wall")
  state.running, state.output, state.cmd = true, {}, cmd
  vim.notify("実行中… " .. table.concat(cmd, " "), vim.log.levels.INFO, { id = "verify", title = "Verify" })

  local started = vim.uv.hrtime()
  local collect = function(_, data)
    if data then
      vim.list_extend(state.output, vim.split(data, "\n", { trimempty = true }))
    end
  end
  local ok, err = pcall(vim.system, cmd, { cwd = root, text = true, stdout = collect, stderr = collect }, function(result)
    local elapsed = (vim.uv.hrtime() - started) / 1e9
    vim.schedule(function()
      on_done(result.code, elapsed, cmd)
    end)
  end)
  if not ok then
    state.running = false
    vim.notify("verify を起動できませんでした: " .. tostring(err), vim.log.levels.ERROR)
  end
end

--- 直前の verify の全出力をスクラッチバッファで開く
function M.show_log()
  if #state.output == 0 then
    vim.notify("verify の出力はまだありません", vim.log.levels.INFO)
    return
  end
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, state.output)
  vim.api.nvim_buf_set_name(buf, "verify://" .. table.concat(state.cmd or {}, " "))
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf })
end

return M
