return {
	lsp = { "gopls" },
	lint = { "golangcilint" },
	filetype = { "go" },
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
}
