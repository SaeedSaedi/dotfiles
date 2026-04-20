local opt = vim.opt

opt.number         = true
opt.relativenumber = true

opt.tabstop     = 4
opt.shiftwidth  = 4
opt.expandtab   = true
opt.autoindent  = true
opt.smartindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = true
opt.incsearch  = true

opt.cursorline = true

opt.termguicolors = true
opt.background    = "dark"
opt.signcolumn    = "yes"
opt.colorcolumn   = "88"

opt.backspace = "indent,eol,start"

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.mouse = "a"

opt.scrolloff     = 8
opt.sidescrolloff = 8

opt.updatetime = 250

opt.undofile = true
opt.undodir  = os.getenv("HOME") .. "/.vim/undodir"

opt.completeopt = "menu,menuone,noselect"

opt.fileencoding = "utf-8"
opt.conceallevel = 0

opt.swapfile = false
opt.backup   = false

opt.cmdheight = 1
opt.hidden    = true

opt.foldmethod = "expr"
opt.foldexpr   = "nvim_treesitter#foldexpr()"
opt.foldenable = false
opt.foldlevel  = 99

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

opt.timeoutlen = 500
