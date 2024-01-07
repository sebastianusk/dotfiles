return {
  { "leoluz/nvim-dap-go", opts = {} },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      ensure_installed = { "delve" },
    },
  },
}
