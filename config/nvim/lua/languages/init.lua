local M = {}

local get_languages = function()
  return {
    require("languages/go"),
    require("languages/javascript"),
    require("languages/json"),
    require("languages/jsonnet"),
    require("languages/helm"),
    require("languages/lua"),
    require("languages/markdown"),
    require("languages/svelte"),
    require("languages/terraform"),
    require("languages/yaml"),
  }
end

M.lsp_config = function()
  local langs = get_languages()
  local list = {}
  for _, lang in pairs(langs) do
    if lang["lsp"] ~= nil then
      table.insert(list, lang["lsp"])
    end
  end
  return list
end

return M
