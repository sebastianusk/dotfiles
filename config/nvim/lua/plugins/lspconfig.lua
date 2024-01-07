return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      { "williamboman/mason-lspconfig.nvim", dependencies = "williamboman/mason.nvim" },
      {
        "nvimdev/lspsaga.nvim",
        keys = {
          { "[n", "<Cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Diagnostic Prev" },
          { "]n", "<Cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Diagnostic Next" },
          { "<Leader>qd", vim.diagnostic.setqflist, desc = "Diagnostic set qf list" },
          { "<Leader>\\", "<cmd>Lspsaga outline<CR>", desc = "Diagnostic set qf list" },
        },
        opts = {
          finder = {
            keys = {
              toggle_or_open = "<CR>",
            },
          },
          rename = {
            keys = {
              quit = "<esc>",
            },
          },
          outline = {
            keys = {
              toggle_or_jump = "<space>",
              jump = "<cr>",
            },
          },
        },
      },
    },
    config = function(_, opts)
      local servers = opts.servers
      local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        has_cmp and cmp_nvim_lsp.default_capabilities() or {},
        opts.capabilities or {}
      )

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})
        require("lspconfig")[server].setup(server_opts)
      end

      -- get all the servers that are available through mason-lspconfig
      local have_mason, mlsp = pcall(require, "mason-lspconfig")
      local all_mslp_servers = {}
      if have_mason then
        all_mslp_servers = vim.tbl_keys(require("mason-lspconfig.mappings.server").lspconfig_to_package)
      end

      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end

      if have_mason then
        mlsp.setup({ ensure_installed = ensure_installed, handlers = { setup } })
      end

      -- Use LspAttach autocommand to only map the following keys
      -- after the language server attaches to the current buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

          -- Buffer local mappings.
          -- See `:help vim.lsp.*` for documentation on any of the below functions
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition", buffer = ev.buf })
          vim.keymap.set("n", "gD", "<Cmd>Lspsaga finder<CR>", { desc = "Go to declaration", buffer = ev.buf })
          vim.keymap.set(
            "n",
            "gt",
            "<Cmd>Lspsaga goto_type_definition<CR>",
            { desc = "Go to type definition", buffer = ev.buf }
          )
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover description", buffer = ev.buf })
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation", buffer = ev.buf })
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
          vim.keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, { desc = "Type Definition", buffer = ev.buf })
          vim.keymap.set("n", "<Leader>rn", "<Cmd>Lspsaga rename<CR>", { desc = "Rename", buffer = ev.buf })
          vim.keymap.set(
            { "n", "v" },
            "<Leader>a",
            "<cmd>Lspsaga code_action<CR>",
            { desc = "Code Action", buffer = ev.buf }
          )
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Go to References", buffer = ev.buf })
        end,
      })
    end,
  },
}
