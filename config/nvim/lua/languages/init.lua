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

M.lsp_install_list = function()
  local langs = get_languages()
  local list = {}
  for _, value in pairs(langs) do
    if value["lsp"] ~= nil then
      table.insert(list, value["lsp"][1])
    end
  end
  return list
end

M.formatters_by_ft = function()
  local langs = get_languages()
  local list = {}
  for _, lang in pairs(langs) do
    if lang["filetype"] ~= nil then
      for _, ft in pairs(lang["filetype"]) do
        if lang["formatters"] ~= nil then
          list[ft] = lang["formatters"]
        end
      end
    end
  end
  return list
end

M.linters_by_ft = function()
  local langs = get_languages()
  local list = {}
  for _, lang in pairs(langs) do
    if lang["filetype"] ~= nil then
      for _, ft in pairs(lang["filetype"]) do
        if lang["linters"] ~= nil then
          local linters = {}
          for _, linter in pairs(lang["linters"]) do
            if type(linter) == "string" then
              table.insert(linters, linter)
            else
              table.insert(linters, linter[1])
            end
          end
          list[ft] = linters
        end
      end
    end
  end
  return list
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
