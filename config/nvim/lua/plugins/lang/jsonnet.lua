local install = require("utls.install")
return {
  install.ensure_installed_mason({
    "jsonnet-language-server",
  }),
  install.ensure_installed_treesitter({ "jsonnet" }),
}
