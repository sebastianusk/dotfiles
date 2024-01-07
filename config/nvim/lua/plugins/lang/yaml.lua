local install = require("utls.install")
return {
  install.ensure_installed_mason({
    "yaml-language-server",
    "yamllint",
    "prettier",
  }),
  install.ensure_installed_treesitter({ "yaml" }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        yaml = { "prettier" },
      },
    },
  },
}
