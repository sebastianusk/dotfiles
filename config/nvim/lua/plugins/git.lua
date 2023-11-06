return {
  {
    "tpope/vim-fugitive",
    lazy = false,
    dependencies = {
      "tpope/vim-unimpaired",
    },
    keys = {
      { "<Leader>gl", ":Gclog -10 -- %<CR>", desc = "Show Commit History" },
      { "<Leader>gg", vim.cmd.Git, desc = "Fugitive" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
}
