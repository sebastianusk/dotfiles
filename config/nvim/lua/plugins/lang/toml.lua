local install = require("utls.install")
local lsp = require("utls.lsp")
return {
  install.ensure_installed_mason({ "taplo" }),
  install.ensure_installed_treesitter({ "toml" }),
  lsp.lsp_config_server({
    taplo = {},
  }),
}
