-- ==========================================================
-- Formatting: 保存時の自動フォーマット
-- ==========================================================

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        html = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        php = { "php_cs_fixer" },
        go = { "goimports", "gofumpt" },
        terraform = { "terraform_fmt" },
        hcl = { "terraform_fmt" },
        sh = { "shfmt" },
      },
      -- フォーマッターが入っていない環境でも保存を妨げない (R-21)
      notify_no_formatters = false,
      format_on_save = {
        timeout_ms = 3000,
        lsp_format = "fallback",
      },
    },
  },
}
