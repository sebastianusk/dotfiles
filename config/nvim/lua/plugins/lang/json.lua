local mason = require("utls.mason")
return {
  mason.ensure_install({
    "json-lsp",
    "jsonlint",
    "prettier",
  }),
}
