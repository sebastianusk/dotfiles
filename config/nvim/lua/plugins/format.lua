return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<Leader>ff",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      desc = "Format buffer",
    },
    {
      "<Leader>fc",
      vim.cmd.ToggleAutoFormat,
      desc = "Toggle Auto Format",
    },
  },
  config = function()
    local formatters = require("languages").formatters_by_ft()
    formatters["*"] = { "trim_whitespace", "trim_newlines " }
    require("conform").setup({
      -- formatters_by_ft = formatters,
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
    })

    vim.b.disable_autoformat = false
    vim.g.disable_autoformat = false
    vim.api.nvim_create_user_command("ToggleAutoFormat", function(args)
      if args.bang then
        -- FormatDisable! will disable formatting just for this buffer
        vim.b.disable_autoformat = not vim.b.disable_autoformat
      else
        vim.g.disable_autoformat = not vim.g.disable_autoformat
      end
    end, {
      desc = "Toggle autoformat-on-save",
      bang = true,
    })
  end,
}
