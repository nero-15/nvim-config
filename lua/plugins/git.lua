-- ==========================================================
-- Git: エージェントの変更をレビューする (R-07)
--   hunk 単位    → gitsigns (]h [h / <leader>gh*)
--   全体・worktree → codediff (<leader>gd / :Worktrees の <C-d>)
--   コミット操作  → lazygit (<leader>gg) / fugitive (:G)
-- ==========================================================

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(buf)
        local gs = require("gitsigns")
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev hunk")
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage hunk")
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gtb", gs.toggle_current_line_blame, "Toggle line blame")
        map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<CR>", "Hunk (text object)")
      end,
    },
  },

  -- codediff: エージェントを走らせたまま、変更をそばからレビューする
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<CR>", desc = "Review changes (working tree)" },
      {
        "<leader>gD",
        function()
          local project = require("workflow.project")
          vim.cmd("CodeDiff " .. project.default_branch(project.cwd()) .. "...")
        end,
        desc = "Review branch (vs default branch)",
      },
      { "<leader>gf", "<cmd>CodeDiff history %<CR>", desc = "File history" },
    },
    opts = {},
  },

  -- fugitive: vimmer の定番 Git クライアント (:G, :Gdiffsplit, :Gread, :GBrowse)
  { "tpope/vim-fugitive", cmd = { "G", "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete" } },

  -- worktree の一覧・切り替え・レビューは独自コマンド :Worktrees (lua/workflow/worktree.lua)
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gw", "<cmd>Worktrees<CR>", desc = "Worktrees (open / diff / claude)" },
    },
  },
}
