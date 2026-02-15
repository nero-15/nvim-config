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

      -- 保存時・読み込み時にリント実行 (リンターが存在する場合のみ)
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("Linting", { clear = true }),
        callback = function()
          local linters = lint.linters_by_ft[vim.bo.filetype] or {}
          local available = vim.tbl_filter(function(name)
            return vim.fn.executable(name) == 1
          end, linters)
          if #available > 0 then
            lint.try_lint(available)
          end
        end,
      })
    end,
  },
}
