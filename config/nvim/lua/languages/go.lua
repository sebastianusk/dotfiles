return {
  lsp = {
    "gopls",
    lspconfig = {
      settings = {
        gopls = {
          analyses = {
            unusedparams = true,
          },
          staticcheck = true,
          gofumpt = true,
        },
      },
    },
  },
  linters = { { "golangcilint", mason = "golangci-lint" } },
  formatters = {
    "gofumpt",
    "goimports",
    "golines",
  },
  filetype = { "go" },
}
