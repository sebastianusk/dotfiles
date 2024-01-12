vim.filetype.add({
  extension = {
    tf = "terraform",
    ["tfvars"] = "terraform", -- Example for .tfvars files
  },
  filename = { [".kube/config"] = "yaml" },
})
