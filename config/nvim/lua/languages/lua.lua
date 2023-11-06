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
  plugins = { "folke/neodev.nvim", opts = {}, dependencies = "nvim-cmp" },
}
