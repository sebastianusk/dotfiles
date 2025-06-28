return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      {
        "<leader>Tj",
        ":ToggleTerm direction=vertical<CR>",
        desc = "Toggle terminal vertically",
      },
      {
        "<leader>Tk",
        ":ToggleTerm direction=horizontal<CR>",
        desc = "Toggle terminal horizontally",
      },
    },
    config = true,
  },
}
