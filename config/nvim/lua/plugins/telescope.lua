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
    {
      "<leader>P",
      function()
        require("telescope.builtin").find_files({
          -- Use the 'fd' command explicitly with flags to include hidden and ignored files
          find_command = { "fd", "--type", "f", "--hidden", "--no-ignore", "." },
        })
      end,
      desc = "Telescope Find Files (incl. hidden & ignored)",
    },
  },
  config = function()
    local actions = require("telescope.actions")
    require("telescope").setup({
      defaults = {
        mappings = {
          i = {
            ["<esc>"] = actions.close,
            ["<C-j>"] = actions.cycle_previewers_next,
            ["<C-k>"] = actions.cycle_previewers_prev,
          },
        },
        layout_strategy = "vertical",
      },
      pickers = {
        find_files = {
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
        live_grep = {
          additional_args = { "--hidden", "--no-ignore-vcs" },
        },
      },
    })
    require("telescope").load_extension("undo")
  end,
}
