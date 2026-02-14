-- ==========================================================
-- Editor: ファイルツリー、ジャンプ、ファイル切替
-- ==========================================================

return {
  -- ──────────────────────────────────────
  -- neo-tree: ファイルツリー
  -- ──────────────────────────────────────
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "File Explorer" },
      { "<leader>ge", "<cmd>Neotree git_status<CR>", desc = "Git Explorer" },
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,  -- ファイル変更を自動検知
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = false,
        },
      },
      window = {
        width = 30,
        mappings = {
          ["<space>"] = "none",  -- leader key と競合しない
        },
      },
    },
  },

  -- ──────────────────────────────────────
  -- telescope: ファジーファインダー
  -- ──────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fs", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<leader>fd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = { preview_width = 0.55 },
          },
        },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- ──────────────────────────────────────
  -- flash.nvim: 画面内の任意の場所に2-3キーでジャンプ
  -- ──────────────────────────────────────
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    keys = {
      { "s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash" },
      { "S", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash Treesitter" },
    },
    opts = {},
  },

  -- ──────────────────────────────────────
  -- harpoon: 常用ファイルへの瞬間アクセス
  -- ──────────────────────────────────────
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add" },
      { "<leader>hh", function()
        local harpoon = require("harpoon")
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, desc = "Harpoon menu" },
      { "<leader>1", function() require("harpoon"):list():select(1) end, desc = "Harpoon 1" },
      { "<leader>2", function() require("harpoon"):list():select(2) end, desc = "Harpoon 2" },
      { "<leader>3", function() require("harpoon"):list():select(3) end, desc = "Harpoon 3" },
      { "<leader>4", function() require("harpoon"):list():select(4) end, desc = "Harpoon 4" },
    },
    config = function()
      require("harpoon"):setup()
    end,
  },

  -- ──────────────────────────────────────
  -- undotree: 変更履歴のツリー表示
  -- ──────────────────────────────────────
  {
    "mbbill/undotree",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<CR>", desc = "Undotree" },
    },
  },

  -- ──────────────────────────────────────
  -- which-key: キーバインドのチートシート
  -- ──────────────────────────────────────
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Harpoon" },
        { "<leader>b", group = "Buffer" },
        { "<leader>a", group = "AI" },
        { "<leader>c", group = "Code" },
      },
    },
  },

  -- ──────────────────────────────────────
  -- autopairs: 括弧の自動補完
  -- ──────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- ──────────────────────────────────────
  -- comment: コメントトグル
  -- ──────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Toggle comment" },
      { "gc", mode = "v", desc = "Toggle comment" },
    },
    opts = {},
  },

  -- ──────────────────────────────────────
  -- surround: 囲み文字の操作
  -- cs"' → ダブルクォートをシングルクォートに
  -- ds" → ダブルクォートを削除
  -- ysiw" → 単語をダブルクォートで囲む
  -- ──────────────────────────────────────
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- ──────────────────────────────────────
  -- todo-comments: TODO/FIXME/HACK をハイライト＋検索
  -- ──────────────────────────────────────
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
      { "<leader>ft", "<cmd>TodoTelescope<CR>", desc = "Find TODOs" },
    },
    opts = {},
  },

  -- ──────────────────────────────────────
  -- lazygit: Nvim 内から Git 操作
  -- ──────────────────────────────────────
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    keys = {
      { "<leader>gg", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },

  -- ──────────────────────────────────────
  -- vim-tmux-navigator: Nvim/tmux ペイン間をシームレス移動
  -- C-h/j/k/l で Nvim ウィンドウも tmux ペインも区別なく移動
  -- ──────────────────────────────────────
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
  },
}
