return {
	{ "williamboman/mason.nvim", conf = {} },
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"mason.nvim",
		},
		config = function()
			local langs = require("languages.newinit")
			require("mason-lspconfig").setup({
				ensure_installed = langs.lsp_install_list(),
			})
		end,
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = {
			"mason.nvim",
		},
		config = function()
			local langs = require("languages.newinit")
			require("mason-tool-installer").setup({
				ensure_installed = langs.tool_install_list(),
			})
		end,
	},
}
