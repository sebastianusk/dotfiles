return {
	--[[ completion ]]
	"hrsh7th/cmp-nvim-lsp",
	"hrsh7th/cmp-buffer",
	"hrsh7th/cmp-path",
	"hrsh7th/cmp-cmdline",
	"L3MON4D3/LuaSnip",
	"saadparwaiz1/cmp_luasnip",
	"nvimdev/lspsaga.nvim",
	"hrsh7th/nvim-cmp",
	--[[ lint ]]
	"mfussenegger/nvim-lint",
	{ "folke/neodev.nvim" },
	--[[ lsp ]]
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		keys = { { "<Leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		cmd = "Mason",
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
		config = function()
			local languages = require("languages")
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = languages.lsp,
			})

			require("neodev").setup({})

			local lspconfig = require("lspconfig")
			require("lspsaga").setup({})

			local cmp = require("cmp")
			cmp.setup({
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" }, -- For luasnip users.
				}, {
					{ name = "buffer" },
				}),
			})

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
			})

			local cmp_autopairs = require("nvim-autopairs.completion.cmp")
			cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

			-- Set up lspconfig.
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			for _, value in pairs(languages.config) do
				local config = value[2]
				config["capabilities"] = capabilities
				lspconfig[value[1]].setup(config)
			end

			-- setup lint
			require("lint").linters_by_ft = languages.lint
			vim.api.nvim_create_autocmd({ "BufWritePost" }, {
				callback = function()
					require("lint").try_lint()
				end,
			})

			-- See `:help vim.diagnostic.*` for documentation on any of the below functions
			vim.keymap.set("n", "[n", vim.diagnostic.goto_prev, { desc = "Diagnostic Prev" })
			vim.keymap.set("n", "]n", vim.diagnostic.goto_next, { desc = "Diagnostic Next" })
			vim.keymap.set("n", "<Leader>qq", vim.diagnostic.setqflist, { desc = "Diagnostic set qf list" })

			-- Use LspAttach autocommand to only map the following keys
			-- after the language server attaches to the current buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					-- Enable completion triggered by <c-x><c-o>
					vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

					-- Buffer local mappings.
					-- See `:help vim.lsp.*` for documentation on any of the below functions
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration", buffer = ev.buf })
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", buffer = ev.buf })
					vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover description", buffer = ev.buf })
					vim.keymap.set(
						"n",
						"gi",
						vim.lsp.buf.implementation,
						{ desc = "Go to implementation", buffer = ev.buf }
					)
					--[[ vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts) ]]
					vim.keymap.set(
						"n",
						"<Leader>wa",
						vim.lsp.buf.add_workspace_folder,
						{ desc = "Add workspace folder", buffer = ev.buf }
					)
					vim.keymap.set(
						"n",
						"<Leader>wr",
						vim.lsp.buf.remove_workspace_folder,
						{ desc = "Remove workspace folder", buffer = ev.buf }
					)
					vim.keymap.set("n", "<Leader>wl", function()
						print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
					end, { desc = "List workspace folder", buffer = ev.buf })
					vim.keymap.set(
						"n",
						"<Leader>D",
						vim.lsp.buf.type_definition,
						{ desc = "Type Definition", buffer = ev.buf }
					)
					vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, { desc = "Rename", buffer = ev.buf })
					vim.keymap.set(
						{ "n", "v" },
						"<Leader>a",
						vim.lsp.buf.code_action,
						{ desc = "Code Action", buffer = ev.buf }
					)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to References", buffer = ev.buf })
				end,
			})
		end,
	},
}
