return {
  lsp = {
    "yamlls",
    lspconfig = {
      settings = {
        yaml = {
          schemas = {
            ["https://json.schemastore.org/package.json"] = "/package.json",
          },
          schemaStore = {
            enable = true,
          },
        },
      },
    }
  },
  filetype = { "yaml" },
  linters = { "yamllint" },
  formatters = { "prettier" },
}
