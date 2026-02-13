-- ==========================================================
-- Options: エディタの基本動作
-- ==========================================================

local opt = vim.opt

-- 行番号: 相対行番号 + 現在行は絶対行番号
-- 5j (5行下に移動) が一瞬で計算できるようになる
opt.number = true
opt.relativenumber = true

-- インデント
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.smartindent = true

-- 検索
opt.ignorecase = true       -- 小文字なら大文字小文字無視
opt.smartcase = true        -- 大文字含むなら厳密マッチ
opt.hlsearch = true         -- 検索ハイライト
opt.incsearch = true        -- インクリメンタル検索

-- 表示
opt.termguicolors = true    -- 24bit color
opt.signcolumn = "yes"      -- 左のサインカラムを常に表示(ガタつき防止)
opt.cursorline = true       -- カーソル行をハイライト
opt.scrolloff = 8           -- カーソルの上下に常に8行の余白
opt.sidescrolloff = 8
opt.wrap = false            -- 行の折り返しなし

-- ファイル
opt.swapfile = false        -- スワップファイル不要
opt.backup = false
opt.undofile = true         -- 永続アンドゥ(ファイルを閉じても戻れる)
opt.autoread = true         -- 外部変更の自動読み込み(Claude Codeとの連携で必須)

-- 分割
opt.splitbelow = true       -- 水平分割は下に
opt.splitright = true       -- 垂直分割は右に

-- その他
opt.clipboard = "unnamedplus"  -- システムクリップボードと共有
opt.updatetime = 250           -- CursorHold の待ち時間短縮
opt.timeoutlen = 300           -- キーマップのタイムアウト
opt.mouse = "a"                -- マウス有効(過渡期用。慣れたら消す)
opt.showmode = false           -- ステータスラインに任せる
