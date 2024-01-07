local mason = require("utls.mason")
return {
  mason.ensure_install({
    "marksman",
    "vale",
    "prettier",
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        md = { "prettier" },
      },
    },
  },
}
