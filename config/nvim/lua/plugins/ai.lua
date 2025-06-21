return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = "*", -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  opts = {
    -- add any opts here
    -- for example
    provider = "openai",
    openai = {
      endpoint = "https://api.openai.com/v1",
      model = "gpt-4o", -- your desired model (or use gpt-4o, etc.)
      timeout = 30000, -- timeout in milliseconds
      temperature = 0, -- adjust if needed
      max_tokens = 4096,
      -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
    },
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      return hub and hub:get_active_servers_prompt() or ""
    end,
    -- Using function prevents requiring mcphub before it's loaded
    custom_tools = function()
      return {
        require("mcphub.extensions.avante").mcp_tool(),
      }
    end,
  },
  -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  build = "make",
  -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
    {
      -- Make sure to set this up properly if you have lazy=true
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
    {
      "ravitemer/mcphub.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
      },
      build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
      config = function()
        require("mcphub").setup({
          --- `mcp-hub` binary related options-------------------
          config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Absolute path to MCP Servers config file (will create if not exists)
          port = 37373, -- The port `mcp-hub` server listens to
          shutdown_delay = 60 * 10 * 000, -- Delay in ms before shutting down the server when last instance closes (default: 10 minutes)
          use_bundled_binary = false, -- Use local `mcp-hub` binary (set this to true when using build = "bundled_build.lua")
          mcp_request_timeout = 60000, --Max time allowed for a MCP tool or resource to execute in milliseconds, set longer for long running tasks

          ---Chat-plugin related options-----------------
          auto_approve = false, -- Auto approve mcp tool calls
          auto_toggle_mcp_servers = true, -- Let LLMs start and stop MCP servers automatically
          extensions = {
            avante = {
              make_slash_commands = true, -- make /slash commands from MCP server prompts
            },
          },

          --- Plugin specific options-------------------
          native_servers = {}, -- add your custom lua native servers here
          ui = {
            window = {
              width = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
              height = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
              align = "center", -- "center", "top-left", "top-right", "bottom-left", "bottom-right", "top", "bottom", "left", "right"
              relative = "editor",
              zindex = 50,
              border = "rounded", -- "none", "single", "double", "rounded", "solid", "shadow"
            },
            wo = { -- window-scoped options (vim.wo)
              winhl = "Normal:MCPHubNormal,FloatBorder:MCPHubBorder",
            },
          },
          on_ready = function(hub)
            -- Called when hub is ready
          end,
          on_error = function(err)
            -- Called on errors
          end,
          log = {
            level = vim.log.levels.WARN,
            to_file = false,
            file_path = nil,
            prefix = "MCPHub",
          },
          extensions = {
            avante = {
              make_slash_commands = true, -- make /slash commands from MCP server prompts
            },
          },
        })
      end,
    },
  },
}
