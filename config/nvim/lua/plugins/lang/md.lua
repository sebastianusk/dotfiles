local install = require("utls.install")
return {
  install.ensure_installed_mason({
    "marksman",
    "vale",
    "prettier",
  }),
  install.ensure_installed_treesitter({ "markdown" }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        md = { "prettier" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = { "markdownlint" },
      },
    },
  },
}
