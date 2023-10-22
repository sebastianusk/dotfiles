return {
	"tpope/vim-fugitive",
	lazy = false,
	dependencies = {
		"tpope/vim-unimpaired",
	},
	keys = {
		{ "<leader>gl", ":Gclog -10 -- %<CR>", desc = "Show Commit History" },
		{ "<leader>gg", vim.cmd.Git, desc = "Fugitive" },
	},
}
