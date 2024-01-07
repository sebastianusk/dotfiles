local install = require("utls.install")
return {
  install.ensure_installed_mason({
    "typescript-language-server",
    "eslint_d",
    "prettier",
  }),
  install.ensure_installed_treesitter({
    "typescript",
    "tsx",
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ts = { "prettier" },
      },
    },
  },
}
