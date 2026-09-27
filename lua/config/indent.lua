-- ==========================================================
-- Indent: after/ftplugin から呼ぶインデント設定の共通部品
-- ==========================================================

local M = {}

function M.two_spaces()
  local opt = vim.opt_local
  opt.expandtab = true
  opt.tabstop = 2
  opt.shiftwidth = 2
  opt.softtabstop = 2
end

return M
