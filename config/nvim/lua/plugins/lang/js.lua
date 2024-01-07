local install = require("utls.install")
local lsp = require("utls.lsp")

return {
  install.ensure_installed_mason({
    "eslint_d",
    "prettier",
  }),
  install.ensure_installed_treesitter({
    "typescript",
    "tsx",
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
  lsp.lsp_config_server({
    tsserver = {
      keys = {
        {
          "<leader>co",
          function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { "source.organizeImports.ts" },
                diagnostics = {},
              },
            })
          end,
          desc = "Organize Imports",
        },
        {
          "<leader>cR",
          function()
            vim.lsp.buf.code_action({
              apply = true,
              context = {
                only = { "source.removeUnused.ts" },
                diagnostics = {},
              },
            })
          end,
          desc = "Remove Unused Imports",
        },
      },
      settings = {
        typescript = {
          format = {
            indentSize = vim.o.shiftwidth,
            convertTabsToSpaces = vim.o.expandtab,
            tabSize = vim.o.tabstop,
          },
        },
        javascript = {
          format = {
            indentSize = vim.o.shiftwidth,
            convertTabsToSpaces = vim.o.expandtab,
            tabSize = vim.o.tabstop,
          },
        },
        completions = {
          completeFunctionCalls = true,
        },
      },
    },
  }),
}
