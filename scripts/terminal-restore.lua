-- setup.sh 専用: 既存/未導入が混在してもlazy-lock.jsonの版を再現する。
-- 実lockは書き換えず、一時コピーに対してlazyの更新処理を行う。
local root = vim.fs.dirname(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)))
local source = root .. "/lazy-lock.json"
local temporary = vim.fn.tempname() .. ".json"

local function read(path)
  local file = assert(io.open(path, "rb"))
  local contents = file:read("*a")
  file:close()
  return contents
end

local function write(path, contents)
  local file = assert(io.open(path, "wb"))
  assert(file:write(contents))
  assert(file:close())
end

local ok, err = xpcall(function()
  local original = read(source)
  local pinned = vim.json.decode(original)
  write(temporary, original)
  vim.g.nvim_setup_restore = true
  vim.g.nvim_setup_lockfile = temporary
  vim.opt.loadplugins = true -- -u NONE / -l は既定でplugin読み込みを無効にする。
  vim.opt.runtimepath:prepend(root)
  dofile(root .. "/init.lua")

  local config = require("lazy.core.config")
  local manager = require("lazy.manage")
  local lock = require("lazy.manage.lock")
  local function assert_tasks()
    for name, plugin in pairs(config.plugins) do
      for _, task in ipairs(plugin._.tasks or {}) do
        assert(not task:has_errors(), name .. ": " .. task:output(vim.log.levels.ERROR))
      end
    end
  end

  -- restoreのlock書込みから未導入pluginが消えるため、install前に原本へ戻す。
  manager.restore({ wait = true, show = false })
  assert_tasks()
  write(temporary, original)
  lock._loaded = false
  manager.install({ wait = true, show = false, lockfile = true })
  assert_tasks()

  for name, plugin in pairs(config.plugins) do
    if plugin.url and not plugin._.is_local then
      assert(plugin._.installed, name .. ": 未インストール")
      local expected = assert(pinned[name], name .. ": lockfileに固定版がありません")
      local actual = vim.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }, { text = true }):wait()
      assert(actual.code == 0 and vim.trim(actual.stdout) == expected.commit, name .. ": 固定版と不一致")
    end
  end
  assert(read(source) == original, "lazy-lock.jsonが変更されました")
  print("[pass] 管理対象プラグインの固定版を再現 / lazy-lock.json不変")
end, debug.traceback)

os.remove(temporary)
if not ok then
  io.stderr:write(tostring(err), "\n")
  vim.cmd("cquit 1")
end
