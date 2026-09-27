-- ==========================================================
-- which-key: キーを押す途中でガイドを出す (R-11, R-12)
-- Leader グループの地図。新しいキーは必ずどこかのグループに属させる
-- ==========================================================

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = function(ctx)
        return ctx.plugin and 0 or 300
      end,
      spec = {
        { "<leader>a", group = "AI (Claude)" },
        { "<leader>b", group = "Buffer" },
        { "<leader>c", group = "Code" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git / Worktree" },
        { "<leader>gh", group = "Hunk" },
        { "<leader>h", group = "Harpoon" },
        { "<leader>m", group = "Markdown / Preview" },
        { "<leader>q", group = "Session" },
        { "<leader>r", group = "Replace / Rename" },
        { "<leader>s", group = "Spec (外部メモリ)" },
        { "<leader>t", group = "Toggle" },
        { "<leader>v", group = "Verify (停止条件)" },
        { "<leader>x", group = "Quickfix / Diagnostics" },
        { "<leader><Tab>", group = "Tab (worktree)" },
        { "[", group = "Prev" },
        { "]", group = "Next" },
        { "g", group = "Goto" },
        { "gr", group = "LSP" },
        { "z", group = "Fold / View" },
      },
    },
    keys = {
      { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer keymaps" },
    },
  },
}
