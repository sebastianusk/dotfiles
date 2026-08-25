return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    config = function()
      local parsers = {
        "bash",
        "c",
        "diff",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "graphql",
        "hcl",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonnet",
        "lua",
        "luadoc",
        "luap",
        "markdown",
        "markdown_inline",
        "ninja",
        "prisma",
        "python",
        "query",
        "regex",
        "rst",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }

      vim.list_extend(parsers, require("utls.install").get_treesitter_parsers())
      local uniqueParsers = {}
      parsers = vim.tbl_filter(function(parser)
        if uniqueParsers[parser] then
          return false
        end
        uniqueParsers[parser] = true
        return true
      end, parsers)

      local alreadyInstalled = require("nvim-treesitter.config").get_installed("parsers")
      local parsersToInstall = vim
        .iter(parsers)
        :filter(function(parser)
          return not vim.tbl_contains(alreadyInstalled, parser)
        end)
        :totable()

      require("nvim-treesitter").install(parsersToInstall)

      vim.treesitter.language.register("bash", "sh")

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "*",
        callback = function()
          local ok = pcall(vim.treesitter.start)
          if not ok then
            return
          end

          local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
          local queryOk, indentQuery = false, nil
          if lang then
            queryOk, indentQuery = pcall(vim.treesitter.query.get, lang, "indents")
          end
          if queryOk and indentQuery then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v",
            ["@function.outer"] = "V",
            ["@class.outer"] = "V",
          },
          include_surrounding_whitespace = false,
        },
        move = {
          set_jumps = true,
        },
      })

      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")

      vim.keymap.set({ "x", "o" }, "af", function()
        select.select_textobject("@function.outer", "textobjects")
      end, { desc = "Select around function" })
      vim.keymap.set({ "x", "o" }, "if", function()
        select.select_textobject("@function.inner", "textobjects")
      end, { desc = "Select inner function" })
      vim.keymap.set({ "x", "o" }, "ac", function()
        select.select_textobject("@class.outer", "textobjects")
      end, { desc = "Select around class" })
      vim.keymap.set({ "x", "o" }, "ic", function()
        select.select_textobject("@class.inner", "textobjects")
      end, { desc = "Select inner class" })
      vim.keymap.set({ "x", "o" }, "at", function()
        select.select_textobject("@statement.outer", "textobjects")
      end, { desc = "Select around statement" })
      vim.keymap.set({ "x", "o" }, "ab", function()
        select.select_textobject("@block.outer", "textobjects")
      end, { desc = "Select around block" })
      vim.keymap.set({ "x", "o" }, "ib", function()
        select.select_textobject("@block.inner", "textobjects")
      end, { desc = "Select inner block" })

      vim.keymap.set({ "n", "x", "o" }, "]m", function()
        move.goto_next_start("@function.outer", "textobjects")
      end, { desc = "Next function start" })
      vim.keymap.set({ "n", "x", "o" }, "]]", function()
        move.goto_next_start("@class.outer", "textobjects")
      end, { desc = "Next class start" })
      vim.keymap.set({ "n", "x", "o" }, "]o", function()
        move.goto_next_start({ "@loop.inner", "@loop.outer" }, "textobjects")
      end, { desc = "Next loop" })
      vim.keymap.set({ "n", "x", "o" }, "]k", function()
        move.goto_next_start("@scope", "locals")
      end, { desc = "Next scope" })
      vim.keymap.set({ "n", "x", "o" }, "]z", function()
        move.goto_next_start("@fold", "folds")
      end, { desc = "Next fold" })
      vim.keymap.set({ "n", "x", "o" }, "]t", function()
        move.goto_next_start("@statement.outer", "textobjects")
      end, { desc = "Next statement" })
      vim.keymap.set({ "n", "x", "o" }, "]M", function()
        move.goto_next_end("@function.outer", "textobjects")
      end, { desc = "Next function end" })
      vim.keymap.set({ "n", "x", "o" }, "][", function()
        move.goto_next_end("@class.outer", "textobjects")
      end, { desc = "Next class end" })
      vim.keymap.set({ "n", "x", "o" }, "[m", function()
        move.goto_previous_start("@function.outer", "textobjects")
      end, { desc = "Previous function start" })
      vim.keymap.set({ "n", "x", "o" }, "[[", function()
        move.goto_previous_start("@class.outer", "textobjects")
      end, { desc = "Previous class start" })
      vim.keymap.set({ "n", "x", "o" }, "[t", function()
        move.goto_previous_start("@statement.outer", "textobjects")
      end, { desc = "Previous statement" })
      vim.keymap.set({ "n", "x", "o" }, "[M", function()
        move.goto_previous_end("@function.outer", "textobjects")
      end, { desc = "Previous function end" })
      vim.keymap.set({ "n", "x", "o" }, "[]", function()
        move.goto_previous_end("@class.outer", "textobjects")
      end, { desc = "Previous class end" })
      vim.keymap.set({ "n", "x", "o" }, "]d", function()
        move.goto_next("@conditional.outer", "textobjects")
      end, { desc = "Next conditional" })
      vim.keymap.set({ "n", "x", "o" }, "[d", function()
        move.goto_previous("@conditional.outer", "textobjects")
      end, { desc = "Previous conditional" })
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
      })
    end,
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      max_lines = 3,
      multiline_threshold = 1,
      separator = "-",
      min_window_height = 20,
      line_numbers = true,
    },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
}
