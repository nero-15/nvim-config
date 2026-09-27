-- ==========================================================
-- Options: エディタの基本動作
-- ==========================================================

local opt = vim.opt

-- 行番号: 相対行番号 + 現在行は絶対行番号
-- 5j (5行下に移動) が一瞬で計算できるようになる (docs/05-learning-path.md Stage 1)
opt.number = true
opt.relativenumber = true

-- インデント (ファイルの種類ごとの上書きは after/ftplugin/)
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true
opt.shiftround = true

-- 検索・置換
opt.ignorecase = true -- 小文字なら大文字小文字無視
opt.smartcase = true -- 大文字含むなら厳密マッチ
opt.inccommand = "split" -- :s の置換結果をライブプレビュー (vimmer 定番)
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob=!.git --glob=!.claude/worktrees"
opt.grepformat = "%f:%l:%c:%m"

-- 表示
opt.termguicolors = true
opt.signcolumn = "yes" -- ガタつき防止
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.smoothscroll = true
opt.winborder = "rounded" -- フロートウィンドウの枠
opt.laststatus = 3 -- ステータスラインは 1 本
opt.showmode = false -- ステータスラインに任せる
opt.pumheight = 12
opt.splitkeep = "screen" -- 分割しても本文が動かない
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " ", diff = "╱" }
opt.conceallevel = 0 -- markdown だけ after/ftplugin で 2 にする

-- ファイル
opt.swapfile = false
opt.undofile = true -- 永続アンドゥ
opt.undolevels = 10000
opt.autoread = true -- 外部変更の自動読み込み (エージェント連携で必須, R-08)
opt.confirm = true -- 未保存で閉じるときは確認

-- 分割
opt.splitbelow = true
opt.splitright = true

-- ジャンプ: CTRL-O / CTRL-I をブラウザの戻る/進むのように
opt.jumpoptions = { "stack", "view" }

-- セッション (persistence.nvim)
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- 折りたたみ: treesitter ベース。開いた状態で始める
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldtext = ""

-- その他
opt.clipboard = "unnamedplus"
opt.updatetime = 250
opt.timeoutlen = 400 -- which-key が出るまでの時間。学習中は少し長め
opt.mouse = "a"
opt.virtualedit = "block" -- 矩形選択で行末を越えられる
opt.completeopt = { "menu", "menuone", "noselect" }

-- 診断の表示
vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  virtual_text = { spacing = 2, source = "if_many" },
  float = { source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    },
  },
})
