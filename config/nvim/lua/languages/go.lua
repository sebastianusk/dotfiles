return {
	lsp = { "gopls" },
	lint = { "golangcilint" },
	filetype = { "go" },
	formatter = {
		require("formatter.filetypes.go"),
	},
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
