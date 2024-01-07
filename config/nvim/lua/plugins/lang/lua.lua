local mason = require("utls.mason")
return {
  { "folke/neodev.nvim", opts = {}, dependencies = "nvim-cmp" },
  mason.ensure_install({
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
