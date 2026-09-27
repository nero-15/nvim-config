-- ==========================================================
-- Navigation: ファイル・画面内・プロジェクト間を跳ぶ
-- ==========================================================

return {
  -- oil.nvim: ディレクトリをバッファとして編集する (vimmer 定番)
  -- 行を書き換えて :w → リネーム、dd して :w → 削除、yy/p → コピー
  {
    "stevearc/oil.nvim",
    lazy = false, -- `nvim .` でディレクトリを開いたときに必要
    dependencies = { "nvim-mini/mini.icons" },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Parent directory (oil)" },
    },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      skip_confirm_for_simple_edits = true,
      keymaps = {
        ["<C-h>"] = false, -- ウィンドウ移動と衝突させない
        ["<C-l>"] = false,
        ["<C-r>"] = "actions.refresh",
        ["q"] = "actions.close",
      },
    },
  },

  -- flash.nvim: 画面内の任意の場所に 2〜3 キーで
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { search = { enabled = false } } },
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash treesitter" },
      { "r", function() require("flash").remote() end, mode = "o", desc = "Remote flash" },
      { "R", function() require("flash").treesitter_search() end, mode = { "o", "x" }, desc = "Treesitter search" },
    },
  },

  -- harpoon: 常用ファイルへの瞬間アクセス
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = function()
      local keys = {
        { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
        {
          "<leader>hh",
          function()
            local harpoon = require("harpoon")
            harpoon.ui:toggle_quick_menu(harpoon:list())
          end,
          desc = "Harpoon menu",
        },
      }
      for i = 1, 4 do
        table.insert(keys, {
          "<leader>" .. i,
          function() require("harpoon"):list():select(i) end,
          desc = "Harpoon " .. i,
        })
      end
      return keys
    end,
    config = function()
      require("harpoon"):setup()
    end,
  },

  -- persistence.nvim: ディレクトリごとにセッションを自動保存・復元
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session (cwd)" },
      { "<leader>qS", function() require("persistence").select() end, desc = "Select session" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
      { "<leader>qd", function() require("persistence").stop() end, desc = "Don't save this session" },
    },
  },

  -- servery.nvim (実験的): ディレクトリごとの常駐 Neovim サーバーを切り替える
  -- tmux のセッション切り替えを Neovim 内で代替できるか試す (ADR-0003)
  {
    "wurli/servery.nvim",
    cmd = "Sv",
    keys = {
      { "<leader>qp", "<cmd>Sv<CR>", desc = "Switch project server (servery, 実験的)" },
    },
    opts = {
      dirs = function()
        local dirs = vim.fn.globpath(vim.fn.expand("~/devel"), "*/", false, true)
        vim.list_extend(dirs, vim.fn.globpath(vim.fn.expand("~/devel/spbl/repositories"), "*/", false, true))
        return vim.tbl_map(function(dir)
          return (dir:gsub("/$", ""))
        end, dirs)
      end,
      ui = { provider = "snacks" },
    },
  },
}
