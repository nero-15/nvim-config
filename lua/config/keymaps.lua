-- ==========================================================
-- Keymaps: プラグインに依存しない基本の操作体系
-- プラグイン固有のキーは lua/plugins/*.lua の keys に置く
-- Leader グループの一覧は lua/plugins/whichkey.lua
-- ==========================================================

local map = vim.keymap.set

-- ──────────────────────────────────────
-- 基本操作
-- ──────────────────────────────────────

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ──────────────────────────────────────
-- 移動
-- ──────────────────────────────────────

map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })

-- ──────────────────────────────────────
-- 編集
-- ──────────────────────────────────────

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

-- インデント後も選択を維持 (>>>> と連打できる)
map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

map("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to clipboard" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete to void register" })

-- カーソル下の単語を置換する :s を組み立てる (vimmer 定番)
map("n", "<leader>rs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Substitute word (:s)" })

-- ──────────────────────────────────────
-- ウィンドウ (tmux のペインは使わない。分割はすべて Neovim で。ADR-0003)
-- ──────────────────────────────────────

for key, dir in pairs({ h = "left", j = "below", k = "above", l = "right" }) do
  map("n", "<C-" .. key .. ">", "<C-w>" .. key, { desc = "Move to " .. dir .. " window" })
  -- ターミナル (Claude Code) からも同じキーで抜けられる
  map("t", "<C-" .. key .. ">", "<C-\\><C-n><C-w>" .. key, { desc = "Move to " .. dir .. " window" })
end

map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })

-- ──────────────────────────────────────
-- バッファ・タブ (タブ = worktree / 作業文脈の単位)
-- ──────────────────────────────────────

map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "]<Tab>", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[<Tab>", "<cmd>tabprevious<CR>", { desc = "Prev tab" })
map("n", "<leader><Tab>d", "<cmd>tabclose<CR>", { desc = "Close tab" })

-- ──────────────────────────────────────
-- 便利系
-- ──────────────────────────────────────

map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>A", "ggVG", { desc = "Select all" })
map("n", "<leader>cp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  vim.notify("コピー: " .. path)
end, { desc = "Copy relative path" })
map("n", "<leader>cP", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("コピー: " .. path)
end, { desc = "Copy absolute path" })

-- 組み込み undotree (Neovim 0.12+)
map("n", "<leader>u", function()
  vim.cmd.packadd("nvim.undotree")
  vim.cmd("Undotree")
end, { desc = "Undotree" })

-- 診断: 行の詳細
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
