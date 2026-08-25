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
  install.ensure_installed_treesitter({ "json", "json5" }),
  lsp.lsp_config_server({
    jsonls = {
      -- lazy-load schemastore when needed
      before_init = function(_, config)
        config.settings = config.settings or {}
        config.settings.json = config.settings.json or {}
        config.settings.json.schemas = config.settings.json.schemas or {}
        vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
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
