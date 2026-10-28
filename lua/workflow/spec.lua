-- ==========================================================
-- spec: 仕様・計画・タスク (外部メモリ) への一瞬アクセス (R-04)
-- 「記憶はディスクに置く」ので、ディスク上の記憶への入口をまとめる
-- ==========================================================

local project = require("workflow.project")

local M = {}

-- セッション開始時に開く引き継ぎファイルの候補 (上から順に探す)
local TASK_FILES = { "TASKS.md", "docs/tasks.md", "docs/development/tasks.md", "docs/**/tasks.md" }

-- エージェント規約 (最優先で読むもの)
local AGENT_FILES = { "CLAUDE.md", "AGENTS.md", "CONVENTIONS.md", "README.md" }

-- 仕様として扱うディレクトリ
local SPEC_GLOBS = {
  { glob = "plans/**/*.md", kind = "plan" },
  { glob = "docs/**/*.md", kind = "doc" },
  { glob = "docs/**/*.html", kind = "doc" },
  { glob = "docs/**/*.mmd", kind = "doc" },
  { glob = ".claude/skills/**/SKILL.md", kind = "skill" },
  { glob = ".agents/skills/**/SKILL.md", kind = "skill" },
  { glob = ".codex/skills/**/SKILL.md", kind = "skill" },
  { glob = "qa/cases/*.yaml", kind = "qa" },
}

local KIND_ORDER = { agent = 1, task = 2, plan = 3, doc = 4, skill = 5, qa = 6 }

---@param root string
---@return table[]
local function collect(root)
  local seen, items = {}, {}
  local add = function(path, kind)
    if seen[path] or path:find("/node_modules/") then
      return
    end
    seen[path] = true
    table.insert(items, {
      file = path,
      text = vim.fs.relpath(root, path) or path,
      kind = kind,
      mtime = vim.fn.getftime(path),
    })
  end
  for _, rel in ipairs(AGENT_FILES) do
    local path = root .. "/" .. rel
    if vim.uv.fs_stat(path) then
      add(path, "agent")
    end
  end
  local tasks = project.find_first(root, TASK_FILES)
  if tasks then
    add(tasks, "task")
  end
  for _, spec in ipairs(SPEC_GLOBS) do
    for _, path in ipairs(vim.fn.globpath(root, spec.glob, false, true)) do
      add(path, spec.kind)
    end
  end
  -- 種類順 → 新しい順
  table.sort(items, function(a, b)
    if a.kind ~= b.kind then
      return KIND_ORDER[a.kind] < KIND_ORDER[b.kind]
    end
    return a.mtime > b.mtime
  end)
  return items
end

local KIND_LABEL = { agent = "規約", task = "引継", plan = "計画", doc = "文書", skill = "技能", qa = "検査" }

---@param opts? { kinds?: string[], title?: string }
function M.pick(opts)
  opts = opts or {}
  local root = project.root()
  local items = collect(root)
  if opts.kinds then
    items = vim.tbl_filter(function(item)
      return vim.tbl_contains(opts.kinds, item.kind)
    end, items)
  end
  if #items == 0 then
    vim.notify("仕様ファイルが見つかりません: " .. root, vim.log.levels.WARN)
    return
  end
  Snacks.picker.pick({
    title = opts.title or "Spec Hub",
    items = items,
    format = function(item)
      return {
        { "[" .. KIND_LABEL[item.kind] .. "] ", "Special" },
        { item.text, "Normal" },
      }
    end,
    preview = "file",
    matcher = { sort_empty = false },
    sort = { fields = { "score:desc", "idx" } },
  })
end

--- 引き継ぎファイル (TASKS.md など) を開く
function M.tasks()
  local root = project.root()
  local path = project.find_first(root, TASK_FILES)
  if not path then
    vim.notify("引き継ぎファイルがありません。候補: " .. table.concat(TASK_FILES, ", "), vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

--- ADR だけを一覧する
function M.adr()
  local root = project.root()
  local files = vim.fn.globpath(root, "docs/**/adr/*.md", false, true)
  vim.list_extend(files, vim.fn.globpath(root, "docs/adr/*.md", false, true))
  Snacks.picker.pick({
    title = "ADR",
    items = vim.tbl_map(function(path)
      return { file = path, text = vim.fs.relpath(root, path) or path }
    end, vim.fn.uniq(vim.fn.sort(files))),
    format = "file",
    preview = "file",
  })
end

--- docs / plans の中だけを grep する
function M.grep()
  local root = project.root()
  local dirs = vim.tbl_filter(function(dir)
    return vim.fn.isdirectory(dir) == 1
  end, { root .. "/docs", root .. "/plans" })
  Snacks.picker.grep({ title = "Grep specs", dirs = #dirs > 0 and dirs or { root }, glob = { "*.md", "*.yaml", "*.html", "*.mmd" } })
end

return M
