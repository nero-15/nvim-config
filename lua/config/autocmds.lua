-- ==========================================================
-- Autocmds: 自動コマンド
-- ファイルの種類ごとの設定は after/ftplugin/<filetype>.lua に置く
-- ==========================================================

local augroup = function(name)
  return vim.api.nvim_create_augroup(name, { clear = true })
end
local autocmd = vim.api.nvim_create_autocmd

-- ──────────────────────────────────────
-- 外部変更の即時反映と可視化 (R-08)
-- エージェントがファイルを書き換えたら、バッファに反映して通知する
-- ──────────────────────────────────────

local reload = augroup("AutoReload")
autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave", "TermClose" }, {
  group = reload,
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- フォーカスが無いときも 1 秒ごとに確認 (横で Claude が書き換えている最中を見たい)
local CHECK_INTERVAL_MS = 1000
local timer = vim.uv.new_timer()
if timer then
  timer:start(CHECK_INTERVAL_MS, CHECK_INTERVAL_MS, vim.schedule_wrap(function()
    if vim.fn.getcmdwintype() == "" and vim.fn.mode() ~= "c" then
      vim.cmd("silent! checktime")
    end
  end))
end

-- 1 秒の間に更新されたファイルをまとめて 1 回だけ通知する
local changed = {}
local flush_scheduled = false
autocmd("FileChangedShellPost", {
  group = reload,
  callback = function(args)
    changed[vim.fn.fnamemodify(args.file, ":.")] = true
    if flush_scheduled then
      return
    end
    flush_scheduled = true
    vim.defer_fn(function()
      local files = vim.tbl_keys(changed)
      changed, flush_scheduled = {}, false
      table.sort(files)
      vim.notify(table.concat(files, "\n"), vim.log.levels.INFO, { title = "外部で更新されました" })
    end, CHECK_INTERVAL_MS)
  end,
})

-- ──────────────────────────────────────
-- 表示
-- ──────────────────────────────────────

autocmd("TextYankPost", {
  group = augroup("YankHighlight"),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ウィンドウサイズが変わったら分割を均等にし直す
autocmd("VimResized", {
  group = augroup("ResizeSplits"),
  command = "tabdo wincmd =",
})

-- 前回のカーソル位置に戻る (コミットメッセージなどは除く)
autocmd("BufReadPost", {
  group = augroup("RestoreCursor"),
  callback = function(args)
    local ft = vim.bo[args.buf].filetype
    if ft == "gitcommit" or ft == "gitrebase" then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ヘルプ・quickfix などは q で閉じる
autocmd("FileType", {
  group = augroup("CloseWithQ"),
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "notify", "gitsigns-blame" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = args.buf, silent = true, desc = "Close" })
  end,
})

-- ──────────────────────────────────────
-- ターミナル
-- ──────────────────────────────────────

autocmd("TermOpen", {
  group = augroup("TerminalSettings"),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- ──────────────────────────────────────
-- 編集
-- ──────────────────────────────────────

-- 保存時に末尾空白を削除 (markdown の改行用の末尾 2 スペースは残す)
autocmd("BufWritePre", {
  group = augroup("TrimWhitespace"),
  callback = function(args)
    if vim.bo[args.buf].filetype == "markdown" or not vim.bo[args.buf].modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- 保存先のディレクトリが無ければ作る (新しい仕様書を docs/features/xxx.md で書き始めるとき)
autocmd("BufWritePre", {
  group = augroup("AutoMkdir"),
  callback = function(args)
    if args.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(args.match) or args.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- ──────────────────────────────────────
-- doc/ の :help タグを生成 (無いか古いときだけ)
-- ──────────────────────────────────────

local doc_dir = vim.fn.stdpath("config") .. "/doc"
if vim.fn.getftime(doc_dir .. "/tags") < vim.fn.getftime(doc_dir .. "/nvim-config.txt") then
  pcall(vim.cmd.helptags, doc_dir)
end
