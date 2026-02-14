-- ==========================================================
-- Tree-sitter: 構文解析ベースのハイライト + テキストオブジェクト
-- 正規表現ではなく構文木で解析するので正確で速い
-- ==========================================================

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
      ensure_installed = {
        "lua",
        "typescript",
        "tsx",
        "javascript",
        "go",
        "php",
        "json",
        "yaml",
        "toml",
        "html",
        "css",
        "bash",
        "markdown",
        "markdown_inline",
        "vim",
        "vimdoc",
        "gitcommit",
        "diff",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",      -- 選択開始
          node_incremental = "<C-space>",    -- 選択範囲を拡大
          scope_incremental = false,
          node_decremental = "<bs>",          -- 選択範囲を縮小
        },
      },
      -- ──────────────────────────────────────
      -- textobjects: 関数・クラス単位の操作
      -- daf (関数削除), yif (関数の中身ヤンク), vac (クラス選択) など
      -- ──────────────────────────────────────
      textobjects = {
        select = {
          enable = true,
          lookahead = true,  -- カーソル先の対象も自動選択
          keymaps = {
            ["af"] = { query = "@function.outer", desc = "関数全体" },
            ["if"] = { query = "@function.inner", desc = "関数の中身" },
            ["ac"] = { query = "@class.outer", desc = "クラス全体" },
            ["ic"] = { query = "@class.inner", desc = "クラスの中身" },
            ["aa"] = { query = "@parameter.outer", desc = "引数全体" },
            ["ia"] = { query = "@parameter.inner", desc = "引数の中身" },
          },
        },
        move = {
          enable = true,
          set_jumps = true,  -- ジャンプリストに追加
          goto_next_start = {
            ["]m"] = { query = "@function.outer", desc = "次の関数" },
            ["]]"] = { query = "@class.outer", desc = "次のクラス" },
          },
          goto_prev_start = {
            ["[m"] = { query = "@function.outer", desc = "前の関数" },
            ["[["] = { query = "@class.outer", desc = "前のクラス" },
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ["<leader>sn"] = { query = "@parameter.inner", desc = "引数を次と入れ替え" },
          },
          swap_previous = {
            ["<leader>sp"] = { query = "@parameter.inner", desc = "引数を前と入れ替え" },
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
