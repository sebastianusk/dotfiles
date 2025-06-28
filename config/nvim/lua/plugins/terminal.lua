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
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 20
        elseif term.direction == "vertical" then
          return math.floor(vim.o.columns * 0.4)
        end
      end,
    },
  },
}
