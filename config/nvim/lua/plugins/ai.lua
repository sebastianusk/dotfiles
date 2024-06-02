return {
  "jackMort/ChatGPT.nvim",
  keys = {
    {
      "<leader>cc",
      vim.cmd.ChatGPT,
      desc = "Chat GPT",
      mode = { "n", "v" },
    },
    {
      "<leader>ce",
      vim.cmd.ChatGPTEditWithInstructions,
      desc = "GPT Edit With Instruction",
      mode = { "n", "v" },
    },
    {
      "<leader>cx",
      "<cmd>ChatGPTRun explain<CR>",
      desc = "GPT Summarize",
      mode = { "n", "v" },
    },
    {
      "<leader>cf",
      "<cmd>ChatGPTRun fix_bugs<CR>",
      desc = "GPT Fix Bugs",
      mode = { "n", "v" },
    },
    {
      "<leader>ct",
      "<cmd>ChatGPTRun add_tests<CR>",
      desc = "GPT Add Test",
      mode = { "n", "v" },
    },
    {
      "<leader>co",
      "<cmd>ChatGPTRun optimize_code<CR>",
      desc = "GPT Optimize Code",
      mode = { "n", "v" },
    },
  },
  event = "VeryLazy",
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "folke/trouble.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("chatgpt").setup({
      api_key_cmd = "op item get NeoVimGPT --fields label=password",
      openai_params = {
        model = "gpt-4o",
      },
      openai_edit_params = {
        model = "gpt-4o",
      },
    })
  end,
}
