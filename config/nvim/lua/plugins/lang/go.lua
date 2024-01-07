local mason = require("utls.mason")
return {
  { "leoluz/nvim-dap-go", opts = {} },
  mason.ensure_install({
    "delve",
    "gofumpt",
    "goimports",
    "golines",
    "golangci-lint",
    "gopls",
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
