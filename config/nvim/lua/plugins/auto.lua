return {
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local npairs = require("nvim-autopairs")
      local Rule = require("nvim-autopairs.rule")

      npairs.setup({
        enable_check_bracket_line = false,
        ignored_next_char = "[%w%.]",
        check_ts = true,
        fast_wrap = {},
        ts_config = {
          lua = { "string" },
          javascript = { "template_string" },
          java = false,
        },
      })

      local ts_conds = require("nvim-autopairs.ts-conds")

      npairs.add_rules({
        Rule("%", "%", "lua"):with_pair(ts_conds.is_ts_node({ "string", "comment" })),
        Rule("$", "$", "lua"):with_pair(ts_conds.is_not_ts_node({ "function" })),
      })
    end,
  },
}
