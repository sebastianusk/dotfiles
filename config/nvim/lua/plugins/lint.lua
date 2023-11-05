return {
	"mfussenegger/nvim-lint",
	config = function()
		local linters = require("languages.newinit").linters_by_ft()
		require("lint").linters_by_ft = linters
		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			callback = function()
				require("lint").try_lint()
			end,
		})
	end,
}
