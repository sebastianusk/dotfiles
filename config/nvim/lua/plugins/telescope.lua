return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "debugloop/telescope-undo.nvim",
  },
  keys = {
    { "<leader>p", require("telescope.builtin").find_files, desc = "Find Files" },
    { "<leader>g", require("telescope.builtin").live_grep, desc = "Search String" },
    { "<leader>hl", require("telescope.builtin").git_bcommits, desc = "Buffer Commit Log" },
    { "<leader>hc", require("telescope.builtin").git_commits, desc = "Commit Log" },
    { "<leader>u", "<cmd>Telescope undo<cr>", desc = "Find Files" },
  },
  config = function()
    local actions = require("telescope.actions")
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = require("telescope.actions").close,
            ["<C-j>"] = actions.cycle_previewers_next,
            ["<C-k>"] = actions.cycle_previewers_prev,
          },
        },
        layout_strategy = "vertical",
      },
    })
    require("telescope").load_extension("undo")
  end,
}
