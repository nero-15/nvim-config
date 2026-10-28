-- ==========================================================
-- Linting: 保存時の静的解析。外部ツールが無ければスキップ (R-21)
-- ==========================================================

return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        -- JS/TS は eslint LSP (lua/plugins/lsp.lua) が担当
        php = { "phpstan" },
        go = { "golangcilint" },
      }

      --- linter の実行ファイルがあるか。識別名 (golangcilint) と実行ファイル名 (golangci-lint) は違うので
      --- 定義の cmd で確認する。定義・cmd とも関数のことがある
      ---@param name string
      ---@return boolean
      local function executable(name)
        local ok, cmd = pcall(function()
          local def = lint.linters[name]
          if type(def) == "function" then def = def() end
          if type(def) ~= "table" then return nil end
          return type(def.cmd) == "function" and def.cmd() or def.cmd
        end)
        return ok and type(cmd) == "string" and vim.fn.executable(cmd) == 1
      end

      -- 保存時・読み込み時にリント実行 (リンターが存在する場合のみ)
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("Linting", { clear = true }),
        callback = function()
          local linters = lint.linters_by_ft[vim.bo.filetype] or {}
          local available = vim.tbl_filter(executable, linters)
          if #available > 0 then
            lint.try_lint(available)
          end
        end,
      })
    end,
  },
}
