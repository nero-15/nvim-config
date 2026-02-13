-- ==========================================================
-- Tree-sitter: 構文解析ベースのハイライト
-- 正規表現ではなく構文木で解析するので正確で速い
-- ==========================================================

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      ensure_installed = {
        "lua",
        "typescript",
        "tsx",
        "javascript",
        "python",
        "rust",
        "go",
        "json",
        "yaml",
        "toml",
        "html",
        "css",
        "bash",
        "markdown",
        "markdown_inline",
        "vim",
        "vimdoc",
        "gitcommit",
        "diff",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",      -- 選択開始
          node_incremental = "<C-space>",    -- 選択範囲を拡大
          scope_incremental = false,
          node_decremental = "<bs>",          -- 選択範囲を縮小
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
