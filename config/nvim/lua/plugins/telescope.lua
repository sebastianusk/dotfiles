return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<C-P>", builtin.find_files, { desc = "Find Files" })
    vim.keymap.set("n", "<C-F>", builtin.live_grep, { desc = "Search All" })
    vim.keymap.set("n", "<leader>|", builtin.treesitter, { desc = "Search Treesitter" })
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
          },
        },
      },
    })
  end,
}
