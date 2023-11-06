return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    -- { "<Leader>\\", ":NvimTreeToggle<CR>" },
    { "<Leader>\\", vim.cmd.NvimTreeToggle, desc = "Tree Toggle" },
    -- { "<Leader>n", ":NvimTreeFindFile<CR>" },
    { "<Leader>n", vim.cmd.NvimTreeFindFile, desc = "Tree find file" },
  },
  config = function()
    -- close when it's the last
    vim.api.nvim_create_autocmd("BufEnter", {
      nested = true,
      callback = function()
        if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
          vim.cmd("quit")
        end
      end,
    })

    -- open when it's directory
    local function open_nvim_tree(data)
      local no_name = data.file == "" and vim.bo[data.buf].buftype == ""
      local directory = vim.fn.isdirectory(data.file) == 1
      if not no_name and not directory then
        return
      end

      if directory then
        vim.cmd.cd(data.file)
      end
      require("nvim-tree.api").tree.open()
    end
    vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

    require("nvim-tree").setup({})
  end,
}
