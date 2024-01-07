local install = require("utls.install")
return {
  install.ensure_installed_mason({
    "terraform-ls",
    "tflint",
    "terraform",
  }),
  install.ensure_installed_treesitter({
    "terraform",
    "hcl",
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
