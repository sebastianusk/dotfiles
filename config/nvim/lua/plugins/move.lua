return {
  "smoka7/hop.nvim",
  config = function()
    local hop = require("hop")
    vim.keymap.set("n", "<Leader><space>", vim.cmd.HopWord, { desc = "Hop Word" })
    hop.setup()
  end,
}
