return {
	lsp = "lua_ls",
	lint = { "luacheck" },
	filetype = { "lua" },
	formatter = {
		require("formatter.filetypes.lua").stylua,
	},
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
