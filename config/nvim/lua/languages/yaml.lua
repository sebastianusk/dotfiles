return {
	lsp = { "yamlls" },
	filetype = { "yaml" },
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
