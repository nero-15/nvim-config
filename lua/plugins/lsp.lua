-- ==========================================================
-- LSP: mason v2 + mason-lspconfig v2 + vim.lsp.config (Neovim 0.11+)
-- サーバーごとの設定は after/lsp/<name>.lua
-- インストール済みのサーバーは mason-lspconfig が自動で vim.lsp.enable する
-- ==========================================================

local SERVERS = {
  "lua_ls", -- Neovim 設定
  "ts_ls", -- TypeScript / JavaScript
  "eslint", -- ESLint (診断 + 自動修正)
  "tailwindcss", -- Tailwind (shadcn/ui)
  "gopls", -- Go
  "intelephense", -- PHP
  "html",
  "cssls",
  "emmet_language_server",
  "jsonls", -- JSON (SchemaStore で .claude/settings.json なども補完)
  "yamlls", -- YAML (qa/cases, GitHub Actions)
  "marksman", -- Markdown: 見出しへの定義ジャンプ・リンク補完・壊れたリンクの検出
  "terraformls", -- Terraform (infra)
  "bashls",
}

return {
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    dependencies = { "saghen/blink.cmp" },
    config = function()
      vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end
          -- 既定キー (0.11+): K hover / grn rename / gra action / grr refs / gri impl / gO symbols
          -- 覚えやすい <leader>c 系の別名も用意する
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>cl", "<cmd>checkhealth vim.lsp<CR>", "LSP info")
        end,
      })
    end,
  },

  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<CR>", desc = "Mason" } },
    opts = {},
  },

  {
    "mason-org/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = SERVERS,
      automatic_enable = true,
    },
  },

  -- JSON / YAML のスキーマ (after/lsp/jsonls.lua, yamlls.lua から使う)
  { "b0o/SchemaStore.nvim", lazy = true, version = false },
}
