local mason = require("utls.mason")
return {
  mason.ensure_install({
    "typescript-language-server",
    "eslint_d",
    "prettier",
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
