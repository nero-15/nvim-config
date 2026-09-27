-- ==========================================================
-- worktree: エージェントの worktree を行き来してレビューする (R-05, R-07)
--   <CR>   新しいタブで開く (:tcd でタブごとに作業ディレクトリを切り替え)
--   <C-d>  既定ブランチとの差分を codediff でレビュー
--   <C-a>  その worktree で Claude を起動
-- ==========================================================

local project = require("workflow.project")

local M = {}

--- `git worktree list --porcelain` を解析する
---@param root string
---@return table[]
function M.list(root)
  local lines = project.git({ "worktree", "list", "--porcelain" }, root)
  if not lines then
    return {}
  end
  local items, current = {}, nil
  for _, line in ipairs(vim.list_extend(lines, { "" })) do
    local key, value = line:match("^(%S+)%s?(.*)$")
    if key == "worktree" then
      current = { path = value }
    elseif current and key == "branch" then
      current.branch = value:gsub("^refs/heads/", "")
    elseif current and key == "HEAD" then
      current.head = value:sub(1, 7)
    elseif current and (key == "locked" or key == "prunable" or key == "detached") then
      current[key] = true
    elseif line == "" and current then
      table.insert(items, current)
      current = nil
    end
  end
  return items
end

---@param path string
---@return string
local function summary(path)
  local status = project.git({ "status", "--short" }, path) or {}
  local log = project.git({ "log", "--oneline", "-8" }, path) or {}
  local lines = { "## 変更中のファイル (" .. #status .. ")" }
  vim.list_extend(lines, #status > 0 and status or { "(なし)" })
  vim.list_extend(lines, { "", "## 直近のコミット" })
  vim.list_extend(lines, log)
  return table.concat(lines, "\n")
end

---@param path string
local function open_tab(path)
  vim.cmd.tabnew()
  vim.cmd.tcd(vim.fn.fnameescape(path))
end

local actions = {
  worktree_open = function(picker, item)
    picker:close()
    open_tab(item.path)
    vim.cmd.edit(vim.fn.fnameescape(item.path))
  end,
  worktree_diff = function(picker, item)
    picker:close()
    open_tab(item.path)
    vim.cmd("CodeDiff " .. project.default_branch(item.path) .. "...")
  end,
  worktree_claude = function(picker, item)
    picker:close()
    open_tab(item.path)
    require("workflow.claude").new()
  end,
}

function M.pick()
  local root = project.root()
  local worktrees = M.list(root)
  if #worktrees == 0 then
    vim.notify("worktree がありません (git リポジトリの外かもしれません)", vim.log.levels.WARN)
    return
  end
  local items = vim.tbl_map(function(wt)
    local agent = project.agent_name(wt.path)
    return {
      text = table.concat({ project.label(wt.path), wt.branch or "", wt.path }, " "),
      path = wt.path,
      label = project.label(wt.path),
      branch = wt.branch or ("detached@" .. (wt.head or "?")),
      agent = agent ~= nil,
      locked = wt.locked,
      preview = { text = summary(wt.path), ft = "markdown" },
    }
  end, worktrees)

  Snacks.picker.pick({
    title = "Worktrees  <CR> 開く / <C-d> 差分レビュー / <C-a> Claude",
    items = items,
    preview = "preview",
    format = function(item)
      return {
        { item.agent and "󰚩 " or " ", item.agent and "Special" or "Directory" },
        { item.label, "Normal" },
        { "  " .. item.branch, "Comment" },
        { item.locked and "  (locked)" or "", "WarningMsg" },
      }
    end,
    confirm = actions.worktree_open,
    actions = actions,
    win = {
      input = {
        keys = {
          ["<C-d>"] = { "worktree_diff", mode = { "n", "i" } },
          ["<C-a>"] = { "worktree_claude", mode = { "n", "i" } },
        },
      },
    },
  })
end

return M
