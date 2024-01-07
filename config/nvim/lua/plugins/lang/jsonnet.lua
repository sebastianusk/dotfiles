local mason = require("utls.mason")
return {
  mason.ensure_install({
    "jsonnet-language-server",
  }),
}
