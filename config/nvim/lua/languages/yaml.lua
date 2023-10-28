return {
	lsp = "yamlls",
	filetype = { "yaml" },
	formatter = {
		require("formatter.filetypes.yaml").prettier,
	},
	lint = { "yamllint" },
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
	},
}
