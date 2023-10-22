vim.g.mapleader = ","

vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "<Leader>ev", ":split $MYVIMRC<CR>")
vim.keymap.set("n", "<Leader>sv", ":source $MYVIMRC<CR>")
vim.keymap.set("n", "<Leader>w", ":set wrap!<CR>")

vim.keymap.set("n", "<Tab>", vim.cmd.bnext)
vim.keymap.set("n", "<S-Tab>", vim.cmd.bprevious)

-- move in bulk
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- make sure paste will stay
vim.keymap.set("x", "<leader>p", [["_dP]])
