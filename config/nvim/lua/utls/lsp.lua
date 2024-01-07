local M = {}

function M.lsp_config_server(server)
  return {
    "neovim/nvim-lspconfig",
    opts = {
      servers = server,
    },
  }
end

return M
