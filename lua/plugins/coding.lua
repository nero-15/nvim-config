-- ==========================================================
-- Coding: 補完・テキストオブジェクト・編集の増幅
-- vimmer が愛用する「動詞 + 対象」を強くするものを中心に (R-12)
-- ==========================================================

return {
  -- blink.cmp: 補完 (nvim-cmp の後継。ADR-0004)
  -- snippets/ (自作) と friendly-snippets を自動で読む
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        list = { selection = { preselect = false, auto_insert = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
      },
      signature = { enabled = true },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- lazydev: Neovim 設定 (Lua) を書くときの補完・型
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "snacks.nvim", words = { "Snacks" } },
      },
    },
  },

  -- mini.ai: テキストオブジェクトの拡張
  --   f 関数 / c クラス / a 引数 / q 引用符 / b 括弧 / t タグ / e 単語の部分 (camelCase)
  --   an( / il" のように n(ext) l(ast) で「次の・前の」対象も選べる
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }),
          e = { -- camelCase / snake_case の 1 語
            { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
            "^().*()$",
          },
          u = ai.gen_spec.function_call(), -- 関数呼び出し
        },
      }
    end,
  },

  -- mini.align: 表や代入を揃える (ga= で = 揃え、ga| で markdown の表)
  { "nvim-mini/mini.align", keys = { { "ga", mode = { "n", "x" } }, { "gA", mode = { "n", "x" } } }, opts = {} },

  -- nvim-surround: 囲みの追加・変更・削除 (ys / cs / ds)
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },

  -- autopairs: 括弧の自動補完
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = { check_ts = true } },

  -- ts-autotag: HTML/JSX タグの自動閉じ・リネーム
  { "windwp/nvim-ts-autotag", event = { "BufReadPost", "BufNewFile" }, opts = {} },

  -- treesj: 1 行 ↔ 複数行の分割/結合 (オブジェクト・引数・配列)
  {
    "Wansmer/treesj",
    keys = { { "<leader>cj", function() require("treesj").toggle() end, desc = "Split / join" } },
    opts = { use_default_keymaps = false, max_join_length = 200 },
  },

  -- dial.nvim: <C-a>/<C-x> で数値以外も増減 (true/false, 日付, && / || など)
  {
    "monaqa/dial.nvim",
    keys = {
      { "<C-a>", function() return require("dial.map").inc_normal() end, expr = true, desc = "Increment" },
      { "<C-x>", function() return require("dial.map").dec_normal() end, expr = true, desc = "Decrement" },
      { "<C-a>", function() return require("dial.map").inc_visual() end, mode = "x", expr = true, desc = "Increment" },
      { "<C-x>", function() return require("dial.map").dec_visual() end, mode = "x", expr = true, desc = "Decrement" },
      { "g<C-a>", function() return require("dial.map").inc_gvisual() end, mode = "x", expr = true, desc = "Increment (連番)" },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal_int,
          augend.integer.alias.hex,
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%Y/%m/%d"],
          augend.constant.alias.bool,
          augend.constant.new({ elements = { "&&", "||" }, word = false, cyclic = true }),
          augend.constant.new({ elements = { "let", "const" } }),
          augend.constant.new({ elements = { "Proposed", "Accepted", "Superseded", "Rejected" } }),
          augend.semver.alias.semver,
        },
      })
    end,
  },

  -- yanky: ヤンク履歴。p した直後に <C-p>/<C-n> で過去のヤンクに差し替え
  {
    "gbprod/yanky.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" }, -- snacks の後に読むと Snacks.picker.yanky が登録される
    opts = { highlight = { timer = 150 } },
    keys = {
      { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put after" },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put before" },
      { "<C-p>", "<Plug>(YankyPreviousEntry)", desc = "Previous yank" },
      { "<C-n>", "<Plug>(YankyNextEntry)", desc = "Next yank" },
      { "<leader>fy", function() Snacks.picker.yanky() end, desc = "Yank history" },
    },
  },

  -- vim-abolish (tpope): 単語の変換と賢い置換
  --   crs snake_case / crc camelCase / crm MixedCase / cru UPPER_CASE / cr- kebab-case
  --   :S/facility{,ies}/school{,s}/g  → 単数・複数・大小文字をまとめて置換
  { "tpope/vim-abolish", event = "VeryLazy" },

  -- vim-repeat: プラグインの操作も . で繰り返せるようにする
  { "tpope/vim-repeat", event = "VeryLazy" },

  -- todo-comments: TODO/FIXME/HACK をハイライト + 一覧
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next TODO" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev TODO" },
      { "<leader>ft", function() Snacks.picker.todo_comments() end, desc = "TODOs" },
    },
  },
}
