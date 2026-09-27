-- ==========================================================
-- project: 「今どのプロジェクト / worktree にいるか」を解決する共通部品
-- タブごとに :tcd で worktree を切り替えるので、常に getcwd() を起点にする
-- ==========================================================

local M = {}

local AGENT_WORKTREE_PATTERN = "/%.claude/worktrees/([^/]+)"

--- 現在のタブの作業ディレクトリ
---@return string
function M.cwd()
  return vim.fn.getcwd()
end

--- git のルート (無ければ cwd)
---@param path? string
---@return string
function M.root(path)
  return vim.fs.root(path or M.cwd(), ".git") or M.cwd()
end

--- エージェントが作った worktree なら名前 (agent-xxxx) を返す
---@param path string
---@return string|nil
function M.agent_name(path)
  return path:match(AGENT_WORKTREE_PATTERN)
end

--- 表示用の短い名前。エージェントの worktree は "repo:agent-xxxx"
---@param path string
---@return string
function M.label(path)
  local agent = M.agent_name(path)
  if agent then
    local repo = vim.fs.basename(path:gsub(AGENT_WORKTREE_PATTERN .. ".*$", ""))
    return repo .. ":" .. agent
  end
  return vim.fs.basename(path)
end

--- 同期で git を実行して stdout の行を返す。失敗したら nil
---@param args string[]
---@param cwd string
---@return string[]|nil
function M.git(args, cwd)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  return vim.split(vim.trim(result.stdout or ""), "\n", { trimempty = true })
end

--- 既定ブランチ (origin/HEAD → main → master の順で探す)
---@param cwd string
---@return string
function M.default_branch(cwd)
  local head = M.git({ "symbolic-ref", "--short", "refs/remotes/origin/HEAD" }, cwd)
  if head and head[1] then
    return head[1]
  end
  for _, name in ipairs({ "main", "master" }) do
    if M.git({ "rev-parse", "--verify", "--quiet", name }, cwd) then
      return name
    end
  end
  return "HEAD"
end

--- 最初に見つかったファイルを返す
---@param root string
---@param candidates string[] root からの相対パス (glob 可)
---@return string|nil
function M.find_first(root, candidates)
  for _, rel in ipairs(candidates) do
    local hits = vim.fn.globpath(root, rel, false, true)
    if #hits > 0 then
      return hits[1]
    end
  end
  return nil
end

return M
