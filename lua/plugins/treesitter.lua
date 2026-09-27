-- ==========================================================
-- Tree-sitter: 構文解析 (Neovim 0.12 + nvim-treesitter main ブランチ)
-- main ブランチでは setup({ ensure_installed }) は効かない。install() を使う
-- ==========================================================

local PARSERS = require("config.parsers")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      if vim.fn.executable("tree-sitter") == 1 then
        ts.install(PARSERS) -- 非同期。入っていれば何もしない
      end

      vim.treesitter.language.register("bash", { "sh", "zsh" })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(args.match)
          if not lang then
            return
          end
          if pcall(vim.treesitter.start, args.buf, lang) then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            return
          end
          -- 未インストールでも対応言語なら自動で入れる
          if vim.fn.executable("tree-sitter") == 1 and vim.tbl_contains(ts.get_available(), lang) then
            ts.install({ lang }):await(function()
              if vim.api.nvim_buf_is_valid(args.buf) then
                pcall(vim.treesitter.start, args.buf, lang)
              end
            end)
          end
        end,
      })
    end,
  },

  -- textobjects: 関数・クラス単位の移動と入れ替え (選択は mini.ai が担当)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")
      local map = vim.keymap.set

      map({ "n", "x", "o" }, "]m", function() move.goto_next_start("@function.outer", "textobjects") end, { desc = "次の関数" })
      map({ "n", "x", "o" }, "[m", function() move.goto_previous_start("@function.outer", "textobjects") end, { desc = "前の関数" })
      map({ "n", "x", "o" }, "]k", function() move.goto_next_start("@class.outer", "textobjects") end, { desc = "次のクラス" })
      map({ "n", "x", "o" }, "[k", function() move.goto_previous_start("@class.outer", "textobjects") end, { desc = "前のクラス" })
      map({ "n", "x", "o" }, "]a", function() move.goto_next_start("@parameter.inner", "textobjects") end, { desc = "次の引数" })
      map({ "n", "x", "o" }, "[a", function() move.goto_previous_start("@parameter.inner", "textobjects") end, { desc = "前の引数" })

      map("n", "<leader>cs", function() swap.swap_next("@parameter.inner") end, { desc = "引数を次と入れ替え" })
      map("n", "<leader>cS", function() swap.swap_previous("@parameter.inner") end, { desc = "引数を前と入れ替え" })
    end,
  },
}
