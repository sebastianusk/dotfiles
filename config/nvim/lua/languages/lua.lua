return {
  lsp = {
    "lua_ls",
    lspconfig = {
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            library = {
              vim.env.VIMRUNTIME,
            },
          },
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
