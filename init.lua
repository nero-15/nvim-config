-- ==========================================================
-- Neovim Configuration
-- Speed-first setup for AI-driven development
-- Claude Code + Agent Teams + tmux workflow
-- ==========================================================

-- Leader key (MUST be set before plugins load)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Core settings
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- Plugin manager: lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup("plugins", {
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
