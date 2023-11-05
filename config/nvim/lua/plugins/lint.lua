return {
  "mfussenegger/nvim-lint",
  config = function()
    local lint = require("lint")
    local languages = require("languages")

    local linters = languages.linters_by_ft()
    lint.linters_by_ft = linters


    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      callback = function()
        lint.try_lint()
      end,
    })
  end,
}
