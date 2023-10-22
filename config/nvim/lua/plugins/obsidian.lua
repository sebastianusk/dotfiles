return {
	"epwalsh/obsidian.nvim",
	lazy = false,
	event = {
		-- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
		-- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
		"BufReadPre /home/sebastianuskh/obsidian/**.md",
		"BufNewFile /home/sebastianuskh/obsidian/**.md",
	},
	keys = {
		{ "<leader>ot", vim.cmd.ObsidianToday, desc = "Obsidian Today" },
		{ "<leader>of", vim.cmd.ObsidianSearch, desc = "Obsidian Search" },
		{ "<leader>op", vim.cmd.ObsidianQuickSwitch, desc = "Obsidian Switch" },
		{ "<leader>ol", vim.cmd.ObsidianFollowLink, desc = "Obsidian Link" },
		{ "<leader>ob", vim.cmd.ObsidianBacklinks, desc = "Obsidian Back Links" },
	},
	dependencies = {
		-- Required.
		"nvim-lua/plenary.nvim",
	},
	opts = {
		dir = "~/obsidian", -- no need to call 'vim.fn.expand' here
		mappings = {},
	},
}
