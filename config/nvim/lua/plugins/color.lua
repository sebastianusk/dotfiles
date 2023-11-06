return {
	{
		"ellisonleao/gruvbox.nvim",
		config = function()
			vim.o.background = "dark"
			vim.cmd("colorscheme gruvbox")
			vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
			vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
		end,
	},
}
