local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  install.ensure_installed_mason({
    "tflint",
  }),
  install.ensure_installed_treesitter({
    "terraform",
    "hcl",
  }),
  lsp.lsp_config_server({
    terraformls = {},
  }),
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        terraform = { "terraform_fmt" },
        tf = { "terraform_fmt" },
        ["terraform-vars"] = { "terraform_fmt" },
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        terraform = { "terraform_validate" },
        tf = { "terraform_validate" },
      },
    },
  },
}
