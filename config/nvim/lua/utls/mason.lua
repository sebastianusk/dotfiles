local M = {}
function M.ensure_install(packages)
  return {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, packages)
    end,
  }
end
return M
