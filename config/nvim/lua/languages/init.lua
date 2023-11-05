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
	local lint = {}
	for _, value in pairs(languages) do
		if value["lsp"] ~= nil then
			table.insert(lsp, value["lsp"][1])
		end
		if value["lspconfig"] ~= nil then
			table.insert(config, { value["lsp"][1], value["lspconfig"] })
		else
			table.insert(config, { value["lsp"][1], {} })
		end
	end

	return {
		lsp = lsp,
		config = config,
		lint = lint,
	}
end

return generate()
