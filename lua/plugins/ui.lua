-- ==========================================================
-- UI: 見た目とステータスライン
-- ==========================================================

return {
  -- ──────────────────────────────────────
  -- カラースキーム: tokyonight
  -- ダーク系で視認性が高い。好みで変えてOK
  -- ──────────────────────────────────────
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- ──────────────────────────────────────
  -- lualine: ステータスライン
  -- ──────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {},
    event = "VeryLazy",
    opts = {
      options = {
        theme = "tokyonight",
        component_separators = { left = "|", right = "|" },
        section_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },  -- 相対パス表示
        lualine_x = { "encoding", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- ──────────────────────────────────────
  -- indent-blankline: インデントガイド
  -- ──────────────────────────────────────
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { enabled = true },
    },
  },

}
