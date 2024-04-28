local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  install.ensure_installed_mason({
    "black",
  }),
  install.ensure_installed_treesitter({ "python" }),
  lsp.lsp_config_server({
    pyright = {},
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        py = { "black" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        markdown = { "ruff" },
      },
    },
  },
}
