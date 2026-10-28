-- ==========================================================
-- Quickfix / 一括置換: 複数ファイルをまとめて扱う (docs/05-learning-path.md Stage 3)
-- verify の結果もここに流れる (R-06)
-- ==========================================================

return {
  -- quicker.nvim: quickfix を編集可能なバッファにする
  -- 行を書き換えて :w → 各ファイルに反映 (vimmer 定番の :cdo より直感的)
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    keys = {
      { "<leader>xq", function() require("quicker").toggle() end, desc = "Quickfix" },
      { "<leader>xl", function() require("quicker").toggle({ loclist = true }) end, desc = "Location list" },
    },
    opts = {
      keys = {
        { ">", function() require("quicker").expand({ before = 2, after = 2, add_to_existing = true }) end, desc = "Expand context" },
        { "<", function() require("quicker").collapse() end, desc = "Collapse context" },
      },
    },
  },

  -- grug-far: プロジェクト全体の検索・置換 (ripgrep)。結果を見ながら置換できる
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    keys = {
      { "<leader>rr", function() require("grug-far").open() end, desc = "Search & replace (project)" },
      {
        "<leader>rw",
        function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
        desc = "Replace word (project)",
      },
      {
        "<leader>rr",
        function() require("grug-far").with_visual_selection() end,
        mode = "x",
        desc = "Replace selection (project)",
      },
    },
    opts = { headerMaxWidth = 80 },
  },

  -- 日常の check / 節目の verify。実装は lua/workflow/verify.lua
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>vc", "<cmd>Check<CR>", desc = "Run check (日常) → quickfix" },
      { "<leader>vv", "<cmd>Verify<CR>", desc = "Run verify (全体) → quickfix" },
      { "<leader>vl", "<cmd>VerifyLog<CR>", desc = "Check / verify log" },
      { "]q", "<cmd>cnext<CR>zz", desc = "Next quickfix" },
      { "[q", "<cmd>cprev<CR>zz", desc = "Prev quickfix" },
    },
  },
}
