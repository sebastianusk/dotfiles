vim.g.mapleader = " "

vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("n", "<Leader>ww", ":set wrap!<CR>", { desc = "Toggle Wrap" })
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

vim.keymap.set("n", "<Tab>", vim.cmd.bnext)
vim.keymap.set("n", "<S-Tab>", vim.cmd.bprevious)

-- move in bulk
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "move the blocked lines down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "move the blocked lines up" })
vim.keymap.set("v", "H", "<gv", { desc = "move the blocked lines left" })
vim.keymap.set("v", "L", ">gv", { desc = "move the blocked lines right" })

-- go to end and start
vim.keymap.set("n", "H", "g^")
vim.keymap.set("n", "L", "g$")

-- make sure paste will stay
vim.keymap.set("v", "p", '"_dP')

vim.keymap.set("n", "<Leader>qq", vim.cmd.cclose, { desc = "Close quick fix" })
vim.keymap.set("n", "<Leader>ll", vim.cmd.lclose, { desc = "Close location list" })
vim.keymap.set("n", "<Leader>cc", vim.cmd.noh, { desc = "Clear highlight" })

vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quick Search" })
vim.keymap.set("n", "[q", vim.cmd.cprevious, { desc = "Prev Quick Search" })
vim.keymap.set("n", "]l", vim.cmd.lnext, { desc = "Next List Search" })
vim.keymap.set("n", "[l", vim.cmd.lprevious, { desc = "Prev List Search" })

vim.keymap.set("n", "<leader>wd", "<C-W><C-O>", { desc = "Close others Windows" })
