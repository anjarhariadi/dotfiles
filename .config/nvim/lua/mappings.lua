require "nvchad.mappings"

-- add yours here
--Saving the file
vim.keymap.set({'n', 'i', 'v'}, '<C-x>', '<Esc>:x<CR>==', { desc = "Save and close the file"})
vim.keymap.set({'n', 'i', 'v'}, '<C-o>', '<Esc>:update<CR> :source<CR>==', { desc = "Save and Source current file"})
vim.keymap.set({'n', 'i', 'v'},'<C-s>', '<Esc>:w<CR>==', { desc = "Save the file"})
vim.keymap.set({'n', 'i', 'v'}, '<C-q>', '<Esc>:q<CR>', { desc = "Exit the file without saving"})

-- Alt + Up/Down Just like in VSCode
vim.keymap.set("n", "<A-Up>", ":m .-2<CR>==", { silent = true })
vim.keymap.set("n", "<A-Down>", ":m .+1<CR>==", { silent = true })
vim.keymap.set("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", { silent = true })
vim.keymap.set("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", { silent = true })
vim.keymap.set("v", "<A-Up>", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("v", "<A-Down>", ":m '>+1<CR>gv=gv", { silent = true })

vim.keymap.set({'n', 'i', 'v'}, '<C-b>', '<Esc>:NvimTreeToggle<CR>', { desc = "Toggle the file tree"})
vim.keymap.set({'n', 'i', 'v'}, '<S-b>', '<Esc>:NvimTreeFocus<CR>', { desc = "Focus to the file tree"})

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
