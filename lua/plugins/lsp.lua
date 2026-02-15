-- ==========================================================
-- LSP: Language Server Protocol
-- コードジャンプ、補完、診断
-- Neovim 0.11+ の vim.lsp.config API を使用
-- ==========================================================

return {
  -- ──────────────────────────────────────
  -- mason: LSP サーバーの自動インストール
  -- ──────────────────────────────────────
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {},
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls",                -- Lua (Neovim 設定用)
        "ts_ls",                 -- TypeScript/JavaScript
        "gopls",                 -- Go
        "intelephense",          -- PHP
        "cssls",                 -- CSS/SCSS/LESS
        "html",                  -- HTML
        "emmet_language_server", -- Emmet (HTML/JSX 展開)
      },
      automatic_installation = true,
    },
  },

  -- ──────────────────────────────────────
  -- LSP の設定 (vim.lsp.config)
  -- ──────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- nvim-cmp との連携 (補完候補の強化)
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = cmp_lsp.default_capabilities(capabilities)
      end

      -- LSP アタッチ時のキーマップ
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("gr", vim.lsp.buf.references, "References")
          map("gi", vim.lsp.buf.implementation, "Implementation")
          map("K", vim.lsp.buf.hover, "Hover docs")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>cr", vim.lsp.buf.rename, "Rename")
          map("<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
          map("]d", vim.diagnostic.goto_next, "Next diagnostic")
          map("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
        end,
      })

      -- 全サーバー共通の capabilities
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      -- Lua (Neovim 設定ファイル用)
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
              checkThirdParty = false,
              library = { vim.env.VIMRUNTIME },
            },
          },
        },
      })

      -- Emmet (HTML/JSX/CSS の省略記法展開)
      vim.lsp.config("emmet_language_server", {
        filetypes = {
          "html", "css", "scss",
          "javascript", "javascriptreact",
          "typescriptreact",
        },
      })

      -- 各サーバーを有効化
      vim.lsp.enable({
        "lua_ls", "ts_ls", "gopls", "intelephense",
        "cssls", "html", "emmet_language_server",
      })
    end,
  },

  -- ──────────────────────────────────────
  -- nvim-cmp: 補完エンジン
  -- ──────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      {
        "L3MON4D3/LuaSnip",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },
}
