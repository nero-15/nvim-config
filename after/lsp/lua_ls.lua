-- lua_ls: Neovim 設定ファイルの編集用
-- after/lsp/ に置くと nvim-lspconfig の既定値の後にマージされる
return {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = { vim.env.VIMRUNTIME },
      },
    },
  },
}
