local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  install.ensure_installed_mason({
    "black",
  }),
  install.ensure_installed_treesitter({ "python", "ninja", "rst" }),
  lsp.lsp_config_server({
    pyright = {},
  }),
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp", -- Use this branch for the new version
    cmd = "VenvSelect",
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
    --  Call config for python files and load the cached venv automatically
    ft = "python",
    keys = { { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv", ft = "python" } },
  },
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
