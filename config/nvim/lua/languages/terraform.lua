return {
	lsp = "terraformls",
	lint = { "tflint" },
	filetype = "terraform",
	formatter = {
		require("formatter.filetypes.terraform"),
	},
	config = {},
}
