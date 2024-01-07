local install = require("utls.install")
return {
  { "leoluz/nvim-dap-go", opts = {} },
  install.ensure_installed_mason({
    "delve",
    "gofumpt",
    "goimports",
    "golines",
    "golangci-lint",
    "gopls",
  }),
  install.ensure_installed_treesitter({
    "go",
    "gomod",
    "gowork",
    "gosum",
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        go = { "goimports", "gofumpt", "golines" },
      },
    },
  },
}
