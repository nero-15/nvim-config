-- ==========================================================
-- Linting: 保存時の静的解析
-- ==========================================================

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        php = { "phpstan" },
        go = { "golangcilint" },
      }

      -- 保存時・読み込み時にリント実行
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("Linting", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
