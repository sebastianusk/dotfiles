return {
	lsp = {
		"lua_ls",
		lspconfig = {
			settings = {
				Lua = {
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		},
	},
	lint = { "luacheck" },
	filetype = { "lua" },
	formatters = { "stylua" },
	linters = { "luacheck" },
	lspconfig = {
		settings = {
			Lua = {
				completion = {
					callSnippet = "Replace",
				},
			},
		},
	},
}
