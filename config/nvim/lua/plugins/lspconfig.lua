return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "nvimdev/lspsaga.nvim",
      "hrsh7th/nvim-cmp",
    },
    config = function()
      local configs = require("languages.newinit").lsp_config()
      local lspconfig = require("lspconfig")
      require("lspsaga").setup({})

      -- Set up lspconfig.
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      for _, value in pairs(configs) do
        if value["lspconfig"] ~= nil then
          local config = value["lspconfig"]
          config["capabilities"] = capabilities
          lspconfig[value[1]].setup(config)
        else
          local config = {}
          config["capabilities"] = capabilities
          lspconfig[value[1]].setup(config)
        end
      end

      -- See `:help vim.diagnostic.*` for documentation on any of the below functions
      vim.keymap.set("n", "[n", vim.diagnostic.goto_prev, { desc = "Diagnostic Prev" })
      vim.keymap.set("n", "]n", vim.diagnostic.goto_next, { desc = "Diagnostic Next" })
      vim.keymap.set("n", "<Leader>qq", vim.diagnostic.setqflist, { desc = "Diagnostic set qf list" })

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration", buffer = ev.buf })
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", buffer = ev.buf })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover description", buffer = ev.buf })
          vim.keymap.set(
            "n",
            "gi",
            vim.lsp.buf.implementation,
            { desc = "Go to implementation", buffer = ev.buf }
          )
          --[[ vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts) ]]
          vim.keymap.set(
            "n",
            "<Leader>wa",
            vim.lsp.buf.add_workspace_folder,
            { desc = "Add workspace folder", buffer = ev.buf }
          )
          vim.keymap.set(
            "n",
            "<Leader>wr",
            vim.lsp.buf.remove_workspace_folder,
            { desc = "Remove workspace folder", buffer = ev.buf }
          )
          vim.keymap.set("n", "<Leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, { desc = "List workspace folder", buffer = ev.buf })
          vim.keymap.set(
            "n",
            "<Leader>D",
            vim.lsp.buf.type_definition,
            { desc = "Type Definition", buffer = ev.buf }
          )
          vim.keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, { desc = "Rename", buffer = ev.buf })
          vim.keymap.set(
            { "n", "v" },
            "<Leader>a",
            vim.lsp.buf.code_action,
            { desc = "Code Action", buffer = ev.buf }
          )
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to References", buffer = ev.buf })
        end,
      })
    end,
  },
}
