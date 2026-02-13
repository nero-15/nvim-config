-- ==========================================================
-- Keymaps: 最速のための操作体系
-- ==========================================================

local map = vim.keymap.set

-- ──────────────────────────────────────
-- 基本操作
-- ──────────────────────────────────────

-- jk で Insert モードを抜ける (Esc より近い)
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- 検索ハイライトを消す
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- ──────────────────────────────────────
-- 移動の高速化
-- ──────────────────────────────────────

-- 半ページ移動後にカーソルを中央に維持
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- 検索結果ジャンプ後もカーソル中央
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- ──────────────────────────────────────
-- 編集
-- ──────────────────────────────────────

-- ビジュアルモードで選択行を上下に移動
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- J (行結合) でカーソル位置を維持
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- ペースト時にレジスタを上書きしない
map("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

-- システムクリップボードへのヤンク (明示的)
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })

-- void レジスタへの削除 (レジスタ汚さない)
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to void register" })

-- ──────────────────────────────────────
-- ウィンドウ操作
-- ──────────────────────────────────────

-- ウィンドウ間移動
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- ウィンドウサイズ調整
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

-- ──────────────────────────────────────
-- バッファ操作
-- ──────────────────────────────────────

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- ──────────────────────────────────────
-- 便利系
-- ──────────────────────────────────────

-- 保存
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })

-- 全選択
map("n", "<leader>a", "ggVG", { desc = "Select all" })

-- カレントファイルのパスをコピー
map("n", "<leader>cp", '<cmd>let @+ = expand("%:p")<CR>', { desc = "Copy file path" })

-- Quick fix リスト移動
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "Prev quickfix" })
