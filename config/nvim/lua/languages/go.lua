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
    }
  },
  linters = { "golangci-lint" },
  formatters = {
    "gofumpt",
    "goimports",
    "golines"
  },
  filetype = { "go" },
}
