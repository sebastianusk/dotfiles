local mason = require("utls.mason")
return {
  mason.ensure_install({
    "yaml-language-server",
    "yamllint",
    "prettier",
  }),
}
