vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set
local o   = { noremap = true, silent = true }

-- Window navigation
map("n", "<C-h>", "<C-w>h", o)
map("n", "<C-j>", "<C-w>j", o)
map("n", "<C-k>", "<C-w>k", o)
map("n", "<C-l>", "<C-w>l", o)

-- Window resize
map("n", "<C-Up>",    ":resize +2<CR>",          o)
map("n", "<C-Down>",  ":resize -2<CR>",           o)
map("n", "<C-Left>",  ":vertical resize -2<CR>",  o)
map("n", "<C-Right>", ":vertical resize +2<CR>",  o)

-- Buffer navigation
map("n", "<S-l>",      ":bnext<CR>",     o)
map("n", "<S-h>",      ":bprevious<CR>", o)
map("n", "<leader>bd", ":bdelete<CR>",   o)

-- Stay in indent mode when shifting
map("v", "<", "<gv", o)
map("v", ">", ">gv", o)

-- Move lines up/down in visual mode
map("v", "<A-j>", ":m '>+1<CR>gv=gv", o)
map("v", "<A-k>", ":m '<-2<CR>gv=gv", o)

-- Quick save/quit
map("n", "<leader>w", ":w<CR>",   o)
map("n", "<leader>q", ":q<CR>",   o)
map("n", "<leader>Q", ":qa!<CR>", o)

-- Clear highlights
map("n", "<leader>h", ":nohlsearch<CR>", o)

-- File tree
map("n", "<leader>e", ":Neotree toggle<CR>", o)

-- Select all
map("n", "<leader>a", "ggVG", o)

-- Better paste (don't yank replaced text)
map("v", "p", '"_dP', o)

-- Diagnostics navigation
map("n", "[d",         vim.diagnostic.goto_prev,  o)
map("n", "]d",         vim.diagnostic.goto_next,  o)
map("n", "<leader>di", vim.diagnostic.open_float, o)

-- jk to exit insert mode
map("i", "jk", "<Esc>", o)
