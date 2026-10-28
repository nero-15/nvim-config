-- ==========================================================
-- Neovim Configuration
-- AI 駆動（仕様駆動）開発のためのエディタ。DNA は docs/00-dna.md
-- 人間は仕様・ループ・評価基準の設計者。エディタは「読む・判断する・舵を切る」道具
-- ==========================================================

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("この設定は Neovim 0.12 以上が前提です（brew upgrade neovim）", vim.log.levels.ERROR)
end

-- Leader key (プラグインより先に設定する)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core settings
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Plugin manager: lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "lazy.nvim の取得に失敗しました:\n" .. out, "ErrorMsg" } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  -- setup.sh の再現用インストールだけは自動installと実lockの更新を抑える。
  lockfile = vim.g.nvim_setup_lockfile or (vim.fn.stdpath("config") .. "/lazy-lock.json"),
  change_detection = { notify = false, enabled = not vim.g.nvim_setup_restore },
  install = { colorscheme = { "tokyonight" }, missing = not vim.g.nvim_setup_restore },
  checker = { enabled = false }, -- 更新は :Lazy で明示的に行う (lazy-lock.json で固定)
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "netrwPlugin", -- ディレクトリは oil.nvim が開く
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
})
