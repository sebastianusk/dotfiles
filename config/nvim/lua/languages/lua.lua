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
	formatter = {
		require("formatter.filetypes.lua").stylua,
	},
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
