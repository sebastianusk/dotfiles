local generate = function()
	local languages = {
		require("languages/go"),
		require("languages/lua"),
		require("languages/markdown"),
		require("languages/terraform"),
	}

	local lsp = {}
	local config = {}
	local formatter = {}
	local lint = {}
	for _, value in pairs(languages) do
		if value["lsp"] ~= nil then
			table.insert(lsp, value["lsp"])
		end
		if value["config"] ~= nil then
			table.insert(config, { value["lsp"], value["config"] })
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
