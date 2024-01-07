local mason = require("utls.mason")
return {
  mason.ensure_install({
    "yaml-language-server",
    "yamllint",
    "prettier",
  }),
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
