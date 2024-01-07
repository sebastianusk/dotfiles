local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  install.ensure_installed_treesitter({ "jsonnet" }),
  lsp.lsp_config_server({
    jsonnet_ls = {},
  }),
}
