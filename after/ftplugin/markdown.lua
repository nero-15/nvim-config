-- Markdown: 仕様書・設計書を読む/書くための設定 (R-01)
local opt = vim.opt_local

opt.wrap = true -- 長い行は折り返して読む
opt.linebreak = true -- 単語の途中で折り返さない
opt.breakindent = true -- 折り返した行もインデントを揃える
opt.conceallevel = 2 -- 記法を隠して整形表示 (render-markdown と協調)
opt.tabstop = 2
opt.shiftwidth = 2
opt.spell = true
opt.spelllang = { "en", "cjk" } -- 日本語をスペルチェック対象外にする

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
end

-- 折り返し行でも見た目どおりに上下移動する (5j のような回数指定は論理行のまま)
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { buffer = true, expr = true, desc = "Down (display line)" })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { buffer = true, expr = true, desc = "Up (display line)" })

--- チェックボックスを切り替える。リスト項目でなければ "- [ ] " を付ける
local function toggle_checkbox()
  local line = vim.api.nvim_get_current_line()
  local new
  if line:match("^%s*[-*+] %[ %]") then
    new = line:gsub("%[ %]", "[x]", 1)
  elseif line:match("^%s*[-*+] %[[xX]%]") then
    new = line:gsub("%[[xX]%]", "[ ]", 1)
  elseif line:match("^%s*[-*+] ") then
    new = line:gsub("^(%s*[-*+] )", "%1[ ] ", 1)
  else
    new = line:gsub("^(%s*)", "%1- [ ] ", 1)
  end
  vim.api.nvim_set_current_line(new)
end

map("n", "<leader>mx", toggle_checkbox, "Toggle checkbox")
vim.keymap.set("n", "<leader>mo", "gO", { buffer = true, remap = true, desc = "Outline (見出し一覧)" })
-- 表を揃える: 表の上で vip → ga| (mini.align)
