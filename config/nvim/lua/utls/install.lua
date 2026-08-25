local M = {}
local treesitter_parsers = {}

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
  for _, package in ipairs(packages) do
    treesitter_parsers[package] = true
  end
  return {}
end

function M.get_treesitter_parsers()
  local parsers = {}
  for parser in pairs(treesitter_parsers) do
    table.insert(parsers, parser)
  end
  return parsers
end

return M
