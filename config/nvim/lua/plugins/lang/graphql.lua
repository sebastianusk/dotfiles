local install = require("utls.install")
local lsp = require("utls.lsp")

return {
  install.ensure_installed_mason({
    "graphql-language-service-cli",
  }),
  install.ensure_installed_treesitter({
    "graphql",
  }),
  lsp.lsp_config_server({
    graphql = {},
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        graphql = { "prettier" },
      },
    },
  },
}
