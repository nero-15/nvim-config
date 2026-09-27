-- ==========================================================
-- Learning: Vim を学び直すための補助輪 (R-11, docs/05-learning-path.md)
-- 慣れたらオフにする。<leader>th / <leader>tp で切り替え
-- ==========================================================

return {
  -- hardtime: jjjj のような非効率な操作にヒントを出す (ブロックはしない)
  {
    "m4xshen/hardtime.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>th", "<cmd>Hardtime toggle<CR>", desc = "Hardtime (操作のヒント)" },
      { "<leader>fH", "<cmd>Hardtime report<CR>", desc = "Hardtime report (悪い癖の集計)" },
    },
    opts = {
      restriction_mode = "hint",
      disable_mouse = false,
      max_count = 4,
      disabled_filetypes = {
        "qf", "lazy", "mason", "oil", "help", "snacks_dashboard", "snacks_picker_list",
        "snacks_picker_input", "snacks_terminal", "codediff-explorer", "markdown",
      },
    },
  },

  -- precognition: 行内の跳び先 (w b e ^ $ など) を薄く表示する
  {
    "tris203/precognition.nvim",
    keys = {
      { "<leader>tp", function() require("precognition").toggle() end, desc = "Precognition (跳び先を表示)" },
    },
    opts = { startVisible = false },
  },

  -- vim-be-good: 移動・削除・置換を競うミニゲーム (ThePrimeagen)。:VimBeGood
  { "ThePrimeagen/vim-be-good", cmd = "VimBeGood" },

  -- レッスン (lessons/*.md) とチートシート (doc/nvim-config.txt)
  {
    "folke/which-key.nvim",
    keys = {
      { "<leader>H", "<cmd>help nvim-config<CR>", desc = "Cheatsheet (:help nvim-config)" },
      { "<leader>L", "<cmd>Lesson<CR>", desc = "Lessons (一覧と進捗)" },
      { "<leader>tl", "<cmd>Lesson!<CR>", desc = "Lesson: 続きから" },
    },
  },
}
