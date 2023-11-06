return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "nvim-telescope/telescope.nvim", -- optional
      "sindrets/diffview.nvim", -- optional
    },
    keys = {
      {
        "<leader>gg",
        function()
          require("neogit").open()
        end,
        desc = "Open Neogit",
      },
    },
    config = true,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {},
  },
}
