return {
	lsp = "terraformls",
	lint = { "tflint" },
	filetype = { "terraform", "tf" },
	formatter = {
		require("formatter.filetypes.terraform"),
	},
	lspconfig = {},
}
