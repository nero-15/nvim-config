-- ==========================================================
-- Markdown / 設計書: 読むための環境 (R-01, R-02, R-03)
--   エディタ内    → render-markdown (表・見出し・callout を整形表示)
--                  + snacks.image (Mermaid をインライン表示。Ghostty のみ)
--   ブラウザ      → live-preview.nvim (md + Mermaid + HTML。入力に追従)
-- ==========================================================

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    keys = {
      { "<leader>tr", "<cmd>RenderMarkdown toggle<CR>", desc = "Render markdown", ft = "markdown" },
    },
    opts = {
      completions = { lsp = { enabled = true } },
      heading = { sign = false, width = "block", min_width = 60 },
      code = { sign = false, width = "block", min_width = 60, border = "thin" },
      pipe_table = { preset = "round" },
      checkbox = { enabled = true },
    },
  },

  {
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    dependencies = { "folke/snacks.nvim" },
    keys = {
      { "<leader>mp", "<cmd>Preview<CR>", desc = "Preview (browser)" },
      { "<leader>mP", "<cmd>PreviewStop<CR>", desc = "Stop preview" },
    },
    config = function()
      require("livepreview.config").set({
        picker = "snacks.picker",
        sync_scroll = true,
      })
    end,
  },
}
