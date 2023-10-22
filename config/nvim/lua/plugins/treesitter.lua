return {
	"nvim-treesitter/nvim-treesitter",
	build = ":TSUpdate",
	keys = {
		{ "z<space>", "za", desc = "trigger fold" },
	},
	config = function()
		local configs = require("nvim-treesitter.configs")

		vim.cmd([[
      set foldmethod=expr
      set foldexpr=nvim_treesitter#foldexpr()
      set nofoldenable                     " Disable folding at startup.
    ]])

		configs.setup({
			sync_install = false,
			highlight = { enable = true },
			indent = { enable = true },
		})
	end,
}
