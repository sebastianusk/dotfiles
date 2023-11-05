local M = {}

local get_languages = function()
	return {
		require("languages/go"),
		require("languages/json"),
		require("languages/lua"),
		require("languages/markdown"),
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

M.tool_install_list = function()
	local langs = get_languages()
	local list = {}
	for _, lang in pairs(langs) do
		if lang["formatters"] ~= nil then
			for _, format in pairs(lang["formatters"]) do
				table.insert(list, format)
			end
		end
		if lang["linters"] ~= nil then
			for _, linter in pairs(lang["linters"]) do
				table.insert(list, linter)
			end
		end
	end
	return list
end

return M
