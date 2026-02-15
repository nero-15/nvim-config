-- ==========================================================
-- Tree-sitter: 構文解析ベースのハイライト + テキストオブジェクト
-- Neovim 0.11+ の新 API を使用
-- ==========================================================

return {
  -- ──────────────────────────────────────
  -- nvim-treesitter: パーサーの管理
  -- ──────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
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
      })
    end,
  },

  -- ──────────────────────────────────────
  -- treesitter-textobjects: 関数・クラス単位の操作
  -- daf (関数削除), yif (関数の中身ヤンク), vac (クラス選択) など
  -- ──────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = function(query)
        return function()
          require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
        end
      end

      local move_next = function(query)
        return function()
          require("nvim-treesitter-textobjects.move").goto_next_start(query, "textobjects")
        end
      end

      local move_prev = function(query)
        return function()
          require("nvim-treesitter-textobjects.move").goto_previous_start(query, "textobjects")
        end
      end

      local swap_next = function(query)
        return function()
          require("nvim-treesitter-textobjects.swap").swap_next(query)
        end
      end

      local swap_prev = function(query)
        return function()
          require("nvim-treesitter-textobjects.swap").swap_previous(query)
        end
      end

      local map = vim.keymap.set

      -- Select: 関数・クラス・引数の選択
      map({ "x", "o" }, "af", select("@function.outer"), { desc = "関数全体" })
      map({ "x", "o" }, "if", select("@function.inner"), { desc = "関数の中身" })
      map({ "x", "o" }, "ac", select("@class.outer"), { desc = "クラス全体" })
      map({ "x", "o" }, "ic", select("@class.inner"), { desc = "クラスの中身" })
      map({ "x", "o" }, "aa", select("@parameter.outer"), { desc = "引数全体" })
      map({ "x", "o" }, "ia", select("@parameter.inner"), { desc = "引数の中身" })

      -- Move: 関数・クラス間のジャンプ
      map({ "n", "x", "o" }, "]m", move_next("@function.outer"), { desc = "次の関数" })
      map({ "n", "x", "o" }, "[m", move_prev("@function.outer"), { desc = "前の関数" })
      map({ "n", "x", "o" }, "]]", move_next("@class.outer"), { desc = "次のクラス" })
      map({ "n", "x", "o" }, "[[", move_prev("@class.outer"), { desc = "前のクラス" })

      -- Swap: 引数の入れ替え
      map("n", "<leader>sn", swap_next("@parameter.inner"), { desc = "引数を次と入れ替え" })
      map("n", "<leader>sp", swap_prev("@parameter.inner"), { desc = "引数を前と入れ替え" })
    end,
  },
}
