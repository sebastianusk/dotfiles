return {
  "kevinhwang91/nvim-ufo",
  dependencies = { "kevinhwang91/promise-async" },
  keys = {
    {
      "zR",
      function()
        require("ufo").openAllFolds()
      end,
      desc = "Open All Folds",
    },
    {
      "zM",
      function()
        require("ufo").closeAllFolds()
      end,
      desc = "Close All Folds",
    },
  },
  event = "BufEnter",
  config = function()
    vim.o.foldcolumn = "0" -- '0' is not bad
    vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true
    require("ufo").setup({
      provider_selector = function()
        return { "treesitter", "indent" }
      end,
    })
  end,
}
