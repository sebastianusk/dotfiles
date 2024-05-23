local install = require("utls.install")
local lsp = require("utls.lsp")

return {
  install.ensure_installed_mason({
    "prisma-language-server",
  }),
  install.ensure_installed_treesitter({
    "prisma",
  }),
  lsp.lsp_config_server({
    prismals = {},
  }),
}
