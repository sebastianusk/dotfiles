local M = {}

function M.ensure_installed_mason(packages)
  return {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, packages)
    end,
  }
end

-- see: https://github.com/nvim-treesitter/nvim-treesitter?tab=readme-ov-file#supported-languages
function M.ensure_installed_treesitter(packages)
  return {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, packages)
      end
    end,
  }
end
return M
