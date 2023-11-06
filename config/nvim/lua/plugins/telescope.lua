return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "debugloop/telescope-undo.nvim",
  },
  keys = {
    { "<C-P>", require("telescope.builtin").find_files, desc = "Find Files" },
    { "<C-F>", require("telescope.builtin").live_grep, desc = "Search String" },
    { "<leader>|", require("telescope.builtin").treesitter, desc = "Treesitter" },
    { "<leader>gh", require("telescope.builtin").git_bcommits, desc = "Buffer Commit History" },
    { "<leader>u", "<cmd>Telescope undo<cr>", desc = "Find Files" },
  },
  config = function()
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
          },
        },
      },
    })
    require("telescope").load_extension("undo")
  end,
}
