local install = require("utls.install")
return {
  install.ensure_installed_mason({
    "json-lsp",
    "jsonlint",
    "prettier",
  }),
  install.ensure_installed_treesitter({ "json", "json5", "jsonc" }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        json = { "prettier" },
      },
    },
  },
}
