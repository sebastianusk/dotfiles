local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  -- yaml schema support
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
  install.ensure_installed_mason({
    "jsonlint",
    "prettier",
  }),
  install.ensure_installed_treesitter({ "json", "json5", "jsonc" }),
  lsp.lsp_config_server({
    jsonls = {
      -- lazy-load schemastore when needed
      on_new_config = function(new_config)
        new_config.settings.json.schemas = new_config.settings.json.schemas or {}
        vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
      end,
      settings = {
        json = {
          format = {
            enable = true,
          },
          validate = { enable = true },
        },
      },
    },
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
