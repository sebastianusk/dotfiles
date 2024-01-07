local mason = require("utls.mason")
return {
  mason.ensure_install({
    "json-lsp",
    "jsonlint",
    "prettier",
  }),
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
