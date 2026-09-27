-- ==========================================================
-- Spec: 外部メモリ (仕様・計画・タスク) への入口 (R-04)
-- 実装は lua/workflow/spec.lua。キーだけをここで定義する
-- ==========================================================

return {
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>ss", "<cmd>Spec<CR>", desc = "Spec Hub (規約・引継・計画・文書)" },
      { "<leader>st", "<cmd>Tasks<CR>", desc = "Tasks (引き継ぎ)" },
      { "<leader>sp", "<cmd>Plans<CR>", desc = "Plans" },
      { "<leader>sa", "<cmd>Adr<CR>", desc = "ADR" },
      { "<leader>sg", "<cmd>SpecGrep<CR>", desc = "Grep in docs / plans" },
      {
        "<leader>sc",
        function()
          local root = require("workflow.project").root()
          vim.cmd.edit(vim.fn.fnameescape(root .. "/CLAUDE.md"))
        end,
        desc = "CLAUDE.md",
      },
    },
  },
}
