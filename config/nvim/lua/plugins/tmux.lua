return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function()
    require('smart-splits').setup({
      -- Ignored buffer types (only while resizing)
      ignored_buftypes = {
        'nofile',
        'quickfix',
        'prompt',
      },
      -- Ignored filetypes (only while resizing)
      ignored_filetypes = { 'NvimTree' },
      -- the default number of lines/columns to resize by at a time
      default_amount = 3,
      -- whether to wrap to opposite side when cursor is at edge
      at_edge = 'wrap',
      -- when moving cursor between splits left or right,
      -- place the cursor on the same row of the *screen*
      -- regardless of line numbers. False uses line numbers.
      move_cursor_same_row = false,
      -- whether the cursor should follow the buffer when swapping
      cursor_follows_swapped_bufs = false,
      -- resize mode options
      resize_mode = {
        -- key to exit resize mode, defaults to <ESC>
        quit_key = '<ESC>',
        -- keys to use for moving in resize mode
        -- in order of left, down, up' right
        resize_keys = { 'h', 'j', 'k', 'l' },
        -- set to true to silence the notifications
        -- when entering/exiting resize mode
        silent = false,
        -- must be functions, they will be executed when
        -- entering or exiting the resize mode
        hooks = {
          on_enter = nil,
          on_leave = nil,
        },
      },
      -- ignore these autocmd events (via :h eventignore) while processing
      -- smart-splits.nvim computations, which involve visiting different
      -- buffers and windows. These events will be ignored during processing,
      -- and un-ignored on completed. This only applies to resize events,
      -- not cursor movement events.
      ignored_events = {
        'BufEnter',
        'WinEnter',
      },
      -- enable or disable a multiplexer integration;
      -- automatically determined, unless explicitly disabled or set,
      -- by checking the $TERM_PROGRAM environment variable,
      -- and the $KITTY_LISTEN_ON environment variable for Kitty
      multiplexer_integration = 'zellij',
      -- disable multiplexer navigation if current multiplexer pane is zoomed
      -- this functionality is only supported on tmux and Wezterm due to kitty
      -- not having a way to check if a pane is zoomed
      disable_multiplexer_nav_when_zoomed = true,
    })
  end,
  keys = {
    -- Navigation
    { "<C-h>", function() require('smart-splits').move_cursor_left() end, desc = "Move to left split" },
    { "<C-j>", function() require('smart-splits').move_cursor_down() end, desc = "Move to below split" },
    { "<C-k>", function() require('smart-splits').move_cursor_up() end, desc = "Move to above split" },
    { "<C-l>", function() require('smart-splits').move_cursor_right() end, desc = "Move to right split" },
    -- Resizing
    { "<A-h>", function() require('smart-splits').resize_left() end, desc = "Resize split left" },
    { "<A-j>", function() require('smart-splits').resize_down() end, desc = "Resize split down" },
    { "<A-k>", function() require('smart-splits').resize_up() end, desc = "Resize split up" },
    { "<A-l>", function() require('smart-splits').resize_right() end, desc = "Resize split right" },
  },
}
