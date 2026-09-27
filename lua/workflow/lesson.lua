-- ==========================================================
-- lesson: Neovim の中で手を動かして学ぶレッスン (R-11, docs/05-learning-path.md)
--   教材の原本は lessons/*.md (リポジトリ)
--   開くと自分用のコピー (stdpath("data")/lessons) を編集する → 何度でもやり直せる
--   進捗 = コピー内のチェックボックス (- [x]) の数。<Space>mx で付け外し
-- ==========================================================

local M = {}

local SRC_DIR = vim.fn.stdpath("config") .. "/lessons"
local DST_DIR = vim.fn.stdpath("data") .. "/lessons"

---@param path string
---@return integer done, integer total
local function progress(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return 0, 0
  end
  local done, total = 0, 0
  for _, line in ipairs(lines) do
    if line:match("^%s*[-*] %[[xX]%]") then
      done, total = done + 1, total + 1
    elseif line:match("^%s*[-*] %[ %]") then
      total = total + 1
    end
  end
  return done, total
end

---@param path string
---@return string
local function title(path)
  local first = vim.fn.readfile(path, "", 1)[1] or ""
  return (first:gsub("^#%s*", ""))
end

--- レッスン一覧 (番号順)
---@return table[]
function M.list()
  local items = {}
  for _, src in ipairs(vim.fn.globpath(SRC_DIR, "*.md", false, true)) do
    local name = vim.fs.basename(src)
    local copy = DST_DIR .. "/" .. name
    local done, total = progress(vim.uv.fs_stat(copy) and copy or src)
    table.insert(items, {
      name = name,
      number = tonumber(name:match("^(%d+)")) or 99,
      src = src,
      copy = copy,
      title = title(src),
      done = done,
      total = total,
    })
  end
  table.sort(items, function(a, b)
    return a.number < b.number
  end)
  return items
end

---@param query string|integer|nil 番号 ("3") または nil (未完了の最初のレッスン)
---@return table|nil
local function find(query)
  local items = M.list()
  if query == nil or query == "" then
    for _, item in ipairs(items) do
      if item.total == 0 or item.done < item.total then
        return item
      end
    end
    return items[#items]
  end
  local number = tonumber(query)
  for _, item in ipairs(items) do
    if item.number == number or item.name:find(tostring(query), 1, true) then
      return item
    end
  end
  return nil
end

---@param item table
local function open_item(item)
  vim.fn.mkdir(DST_DIR, "p")
  if not vim.uv.fs_stat(item.copy) then
    local ok, err = vim.uv.fs_copyfile(item.src, item.copy)
    if not ok then
      vim.notify("レッスンをコピーできません: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd.edit(vim.fn.fnameescape(item.copy))
end

--- レッスンを開く。番号を省略すると、未完了の最初のレッスン
---@param query? string
function M.open(query)
  local item = find(query)
  if not item then
    vim.notify("レッスンが見つかりません: " .. tostring(query), vim.log.levels.WARN)
    return
  end
  open_item(item)
end

--- 自分用のコピーを原本に戻す
---@param query? string 番号。省略すると今開いているレッスン
function M.reset(query)
  local item
  if query == nil or query == "" then
    local current = vim.api.nvim_buf_get_name(0)
    item = vim.iter(M.list()):find(function(i)
      return i.copy == current
    end)
  else
    item = find(query)
  end
  if not item then
    vim.notify("リセットするレッスンを番号で指定してください (:LessonReset 3)", vim.log.levels.WARN)
    return
  end
  local ok, err = vim.uv.fs_copyfile(item.src, item.copy)
  if not ok then
    vim.notify("リセットできません: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if vim.api.nvim_buf_get_name(0) == item.copy then
    vim.cmd("edit!")
  end
  vim.notify("リセットしました: " .. item.title)
end

--- 一覧から選ぶ
function M.pick()
  local items = vim.tbl_map(function(item)
    local bar = item.total > 0 and string.format("%2d/%-2d", item.done, item.total) or "  -  "
    local mark = (item.total > 0 and item.done == item.total) and "✓" or " "
    return vim.tbl_extend("force", item, {
      text = item.title,
      file = vim.uv.fs_stat(item.copy) and item.copy or item.src,
      label = mark .. " " .. bar,
    })
  end, M.list())
  Snacks.picker.pick({
    title = "Lessons  (進捗 = チェックボックスの数。<Space>mx で付け外し)",
    items = items,
    format = function(item)
      local hl = item.label:sub(1, 1) == "✓" and "DiagnosticOk" or "Comment"
      return { { item.label .. "  ", hl }, { item.text, "Normal" } }
    end,
    preview = "file",
    matcher = { sort_empty = false },
    confirm = function(picker, item)
      picker:close()
      open_item(item)
    end,
  })
end

--- :Lesson の補完 (番号)
function M.complete()
  return vim.tbl_map(function(item)
    return tostring(item.number)
  end, M.list())
end

return M
