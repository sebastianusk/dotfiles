local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
  install.ensure_installed_mason({
    "yamllint",
    "prettier",
  }),
  install.ensure_installed_treesitter({ "yaml" }),
  lsp.lsp_config_server({
    yamlls = {
      -- Have to add this for yamlls to understand that we support line folding
      capabilities = {
        textDocument = {
          foldingRange = {
            dynamicRegistration = false,
            lineFoldingOnly = true,
          },
        },
      },
      -- lazy-load schemastore when needed
      before_init = function(_, config)
        config.settings = config.settings or {}
        config.settings.yaml = config.settings.yaml or {}
        local schemas = config.settings.yaml.schemas or {}
        local schemastore = require("schemastore").yaml.schemas()
        if vim.islist(schemas) and vim.islist(schemastore) then
          config.settings.yaml.schemas = vim.list_extend(vim.list_extend({}, schemas), schemastore)
        else
          config.settings.yaml.schemas = vim.deepcopy(schemas)
          for schema, file_matches in pairs(schemastore) do
            if config.settings.yaml.schemas[schema] == nil then
              config.settings.yaml.schemas[schema] = file_matches
            end
          end
        end
      end,
      settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
          keyOrdering = false,
          format = {
            enable = true,
          },
          validate = true,
          schemaStore = {
            -- Must disable built-in schemaStore support to use
            -- schemas from SchemaStore.nvim plugin
            enable = false,
            -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
            url = "",
          },
          schema = {
            kubernetes = "*.yaml",
          },
        },
      },
    },
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
