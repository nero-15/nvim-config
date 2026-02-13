-- ==========================================================
-- Autocmds: 自動コマンド
-- ==========================================================

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- ファイル外部変更の自動読み込み (Claude Code がファイルを書き換えたとき用)
augroup("AutoReload", { clear = true })
autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = "AutoReload",
  command = "checktime",
})

-- ヤンク時にハイライト表示
augroup("YankHighlight", { clear = true })
autocmd("TextYankPost", {
  group = "YankHighlight",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ファイルを開いたとき、前回のカーソル位置に戻る
augroup("RestoreCursor", { clear = true })
autocmd("BufReadPost", {
  group = "RestoreCursor",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ターミナルモードを開いたら自動で Insert モードに入る
augroup("TerminalInsert", { clear = true })
autocmd("TermOpen", {
  group = "TerminalInsert",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})

-- 保存時に末尾空白を自動削除
augroup("TrimWhitespace", { clear = true })
autocmd("BufWritePre", {
  group = "TrimWhitespace",
  pattern = "*",
  command = "%s/\\s\\+$//e",
})

-- Markdown の設定 (設計書閲覧用)
augroup("MarkdownSettings", { clear = true })
autocmd("FileType", {
  group = "MarkdownSettings",
  pattern = "markdown",
  callback = function()
    vim.opt_local.wrap = true          -- Markdown は折り返しあり
    vim.opt_local.linebreak = true     -- 単語の途中で折り返さない
    vim.opt_local.conceallevel = 2     -- Markdown 記法を見やすく表示
  end,
})
