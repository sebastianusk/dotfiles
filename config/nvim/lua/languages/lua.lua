return {
  lsp = {
    "lua_ls",
    lspconfig = {
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    },
  },
  filetype = { "lua" },
  formatters = { "stylua" },
  linters = { "luacheck" },
}
