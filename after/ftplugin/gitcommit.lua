-- コミットメッセージ: conventional commits を書きやすく
local opt = vim.opt_local

opt.spell = true
opt.spelllang = { "en", "cjk" }
opt.textwidth = 72
opt.colorcolumn = "51,73" -- 件名 50 字 / 本文 72 字の目安
