local install = require("utls.install")
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
}
