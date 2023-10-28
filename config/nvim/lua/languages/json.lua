return {
	lsp = "jsonls",
	filetype = { "json" },
	formatter = {
		require("formatter.filetypes.json").prettier,
	},
	lint = { "jsonlint" },
	lspconfig = {},
}
