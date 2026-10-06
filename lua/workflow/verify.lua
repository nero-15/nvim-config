-- ==========================================================
-- verify: 停止条件 (make verify / pnpm verify) をエディタから回す (R-06)
-- 結果は quickfix に流し、]q で赤に直接飛べるようにする
-- ==========================================================

local project = require("workflow.project")

local M = {}

-- 相対パスを実行元の root 基準で解決するための目印 (errorformat の %D = ディレクトリスタック)
local ENTER_DIR = "nvim-verify: Entering directory '%s'"

-- go / golangci-lint / tsc / vitest / playwright / 一般的な file:line:col 形式
local ERRORFORMAT = table.concat({
  "%Dnvim-verify: Entering directory '%f'",
  "%f:%l:%c: %m",
  "%f(%l\\,%c): %m",
  "%f:%l:%c - %m",
  "%\\s%#❯ %f:%l:%c",
  "%\\s%#at %f:%l:%c",
  "%f:%l: %m",
}, ",")

local state = { running = false, output = {}, cmd = nil, root = nil }

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

--- 受信チャンクを行に組み立てる。行の途中で切れた断片はストリームごとに持ち越す
---@param sink string[] 完成した行の追加先
---@return fun(err: string?, data: string?) on_chunk
---@return fun() flush EOF で改行の無い最終行を出す
local function line_reader(sink)
  local partial = ""
  local function on_chunk(_, data)
    if not data then
      return
    end
    local lines = vim.split(partial .. data, "\n", { plain = true })
    partial = table.remove(lines)
    for _, line in ipairs(lines) do
      sink[#sink + 1] = (line:gsub("\r$", ""))
    end
  end
  local function flush()
    if partial ~= "" then
      sink[#sink + 1] = (partial:gsub("\r$", ""))
      partial = ""
    end
  end
  return on_chunk, flush
end

---@param code integer
---@param elapsed number
---@param cmd string[]
---@param root string 実行時の root。cwd が変わっていても診断はここを基準に解決する
local function on_done(code, elapsed, cmd, root)
  state.running = false
  local title = string.format("Verify: %s (%s)", table.concat(cmd, " "), vim.fn.fnamemodify(root, ":~"))
  local lines = { ENTER_DIR:format(root) }
  vim.list_extend(lines, state.output)
  vim.fn.setqflist({}, " ", { title = title, lines = lines, efm = ERRORFORMAT, context = { root = root } })
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
  state.running, state.output, state.cmd, state.root = true, {}, cmd, root
  vim.notify("実行中… " .. table.concat(cmd, " "), vim.log.levels.INFO, { id = "verify", title = "Verify" })

  local started = vim.uv.hrtime()
  local output = state.output
  local on_stdout, flush_stdout = line_reader(output)
  local on_stderr, flush_stderr = line_reader(output)
  local opts = { cwd = root, text = true, stdout = on_stdout, stderr = on_stderr }
  local ok, err = pcall(vim.system, cmd, opts, function(result)
    local elapsed = (vim.uv.hrtime() - started) / 1e9
    vim.schedule(function()
      flush_stdout()
      flush_stderr()
      on_done(result.code, elapsed, cmd, root)
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
  vim.api.nvim_buf_set_name(buf, "verify://" .. (state.root or "") .. " " .. table.concat(state.cmd or {}, " "))
  vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf })
end

return M
