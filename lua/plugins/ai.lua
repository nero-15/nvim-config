-- ==========================================================
-- AI: Claude Code 連携
-- ==========================================================

return {
  -- ──────────────────────────────────────
  -- claudecode.nvim: Claude Code との統合
  -- Neovim 内から Claude Code を操作
  -- ──────────────────────────────────────
  {
    "coder/claudecode.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude Code" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<leader>ao", "<cmd>ClaudeCodeOpen<cr>", desc = "Open Claude Code" },
    },
    opts = {
      terminal_cmd = "claude --dangerously-skip-permissions",
      terminal = {
        split_side = "right",
        split_width_percentage = 0.4,
      },
    },
  },

  -- ──────────────────────────────────────
  -- render-markdown: Markdown のレンダリング強化
  -- 設計書(md)閲覧を快適にする
  -- ──────────────────────────────────────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    ft = { "markdown" },
    opts = {},
  },
}
