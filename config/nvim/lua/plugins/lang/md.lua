local mason = require("utls.mason")
return {
  mason.ensure_install({
    "marksman",
    "vale",
    "prettier",
  }),
}
