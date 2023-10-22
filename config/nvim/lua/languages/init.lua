local generate = function()
	local languages = {
		require("languages/go"),
		require("languages/json"),
		require("languages/lua"),
		require("languages/markdown"),
		require("languages/terraform"),
		require("languages/yaml"),
	}

	local lsp = {}
	local config = {}
	local formatter = {}
	local lint = {}
	for _, value in pairs(languages) do
		if value["lsp"] ~= nil then
			table.insert(lsp, value["lsp"])
		end
		if value["lspconfig"] ~= nil then
			table.insert(config, { value["lsp"], value["lspconfig"] })
		else
			table.insert(config, { value["lsp"], {} })
		end
		if value["formatter"] ~= nil then
			formatter[value["filetype"]] = value["formatter"]
		end
		if value["formatter"] ~= nil then
			lint[value["filetype"]] = value["lint"]
		end
	end

	return {
		lsp = lsp,
		config = config,
		formatter = formatter,
		lint = lint,
	}
end

return generate()
