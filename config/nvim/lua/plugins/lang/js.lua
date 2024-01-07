local mason = require("utls.mason")
return {
  mason.ensure_install({
    "typescript-language-server",
    "eslint_d",
    "prettier",
  }),
}
