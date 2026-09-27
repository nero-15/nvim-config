-- ==========================================================
-- tabline: タブ = 作業文脈 (worktree)。タブごとの cwd を表示する
-- エージェントの worktree は 󰚩 付きで出るので、今どこをレビューしているか見失わない
-- ==========================================================

local project = require("workflow.project")

local M = {}

function M.render()
  local parts = {}
  local current = vim.fn.tabpagenr()
  for nr = 1, vim.fn.tabpagenr("$") do
    local cwd = vim.fn.getcwd(-1, nr)
    local agent = project.agent_name(cwd) ~= nil
    local hl = nr == current and "%#TabLineSel#" or "%#TabLine#"
    local icon = agent and "󰚩 " or ""
    table.insert(parts, string.format("%s%%%dT %d %s%s ", hl, nr, nr, icon, project.label(cwd)))
  end
  return table.concat(parts) .. "%#TabLineFill#%T"
end

function M.setup()
  vim.o.showtabline = 1 -- タブが 2 つ以上のときだけ表示
  vim.o.tabline = "%!v:lua.require'workflow.tabline'.render()"
end

return M
