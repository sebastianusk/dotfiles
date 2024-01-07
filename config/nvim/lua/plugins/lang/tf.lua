local mason = require("utls.mason")
return {
  mason.ensure_install({
    "terraform-ls",
    "tflint",
  }),
}
