return {
  lsp = {
    "yamlls",
    lspconfig = {
      on_attach = function(client, bufnr)
        if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].filetype == "helm" then
          vim.diagnostic.disable()
        end
      end,
      settings = {
        yaml = {
          schemas = {
            ["https://json.schemastore.org/chart.json"] = "templates/*.{yml,yaml}",
          },
          schemaStore = {
            enable = true,
          },
        },
      },
    },
  },
  filetype = { "yaml" },
  linters = { "yamllint" },
  formatters = { "prettier" },
}
