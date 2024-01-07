local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  { "folke/neodev.nvim", opts = {}, dependencies = "nvim-cmp" },
  install.ensure_installed_mason({
    "lua-language-server",
    "luacheck",
    "stylua",
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
    },
  },
  lsp.lsp_config_server({
    lua_ls = {
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
  }),
}
