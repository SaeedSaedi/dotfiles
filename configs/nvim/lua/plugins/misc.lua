return {
  -- Which-key: shows keybinding hints
  {
    "folke/which-key.nvim",
    event  = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.setup({
        plugins = { spelling = { enabled = true } },
        win     = { border = "rounded" },
      })
      wk.add({
        { "<leader>f", group = "Find / Telescope" },
        { "<leader>g", group = "Git" },
        { "<leader>l", group = "LSP" },
        { "<leader>b", group = "Buffer" },
        { "<leader>p", group = "Peek (LSP)" },
        { "<leader>c", group = "Calls / Code" },
        { "<leader>x", group = "Trouble" },
        { "<leader>s", group = "Swap" },
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event  = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({ check_ts = true })
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- Comment with treesitter context (important for PHP with HTML/JS mixed files)
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n",          desc = "Comment line" },
      { "gc",  mode = { "n", "v" }, desc = "Comment" },
      { "gbc", mode = "n",          desc = "Block comment" },
    },
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true, opts = { enable_autocmd = false } },

  -- Surround: cs"' da( ysiw)
  {
    "kylechui/nvim-surround",
    version = "*",
    event   = "VeryLazy",
    config  = true,
  },

  -- Floating terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys    = { { "<leader>t", desc = "Toggle Terminal" } },
    config = function()
      require("toggleterm").setup({
        size         = 15,
        open_mapping = [[<leader>t]],
        direction    = "horizontal",
        close_on_exit = true,
        shell        = vim.o.shell,
        float_opts   = { border = "curved" },
      })
      vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
    end,
  },

  -- Highlight word under cursor
  {
    "RRethy/vim-illuminate",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({
        delay             = 200,
        large_file_cutoff = 2000,
      })
    end,
  },

  -- TODO/FIXME/HACK/BUG highlighting
  {
    "folke/todo-comments.nvim",
    event        = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
    config = true,
  },

  -- Trouble: diagnostics panel
  {
    "folke/trouble.nvim",
    cmd  = { "Trouble" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",              desc = "Diagnostics" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>",      desc = "Symbols" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<cr>",                   desc = "Quickfix" },
    },
    config = true,
  },

  -- Color highlighter (#hex, rgb())
  {
    "NvChad/nvim-colorizer.lua",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("colorizer").setup({
        filetypes = { "*" },
        user_default_options = {
          RGB    = true,
          RRGGBB = true,
          names  = false,
          css    = true,
          css_fn = true,
          mode   = "background",
        },
      })
    end,
  },

  -- Smooth scrolling
  {
    "karb94/neoscroll.nvim",
    event  = "VeryLazy",
    config = function()
      require("neoscroll").setup({ mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>" } })
    end,
  },

  { "nvim-lua/plenary.nvim", lazy = true },
}
