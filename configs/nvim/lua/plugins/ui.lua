return {
  -- Colorscheme: Catppuccin Mocha
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
    lazy     = false,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        integrations = {
          treesitter       = true,
          native_lsp       = { enabled = true },
          telescope        = { enabled = true },
          gitsigns         = true,
          neo_tree         = true,
          mason            = true,
          which_key        = true,
          indent_blankline = { enabled = true },
          bufferline       = true,
          cmp              = true,
          notify           = true,
          mini             = { enabled = true },
        },
      })
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    event        = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme                = "catppuccin-mocha",
          component_separators = { left = "", right = "" },
          section_separators   = { left = "", right = "" },
          globalstatus         = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- Buffer tabs
  {
    "akinsho/bufferline.nvim",
    event        = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          mode               = "buffers",
          separator_style    = "slant",
          diagnostics        = "nvim_lsp",
          always_show_bufferline = false,
          offsets = {
            {
              filetype   = "neo-tree",
              text       = "Explorer",
              highlight  = "Directory",
              text_align = "left",
            },
          },
        },
      })
    end,
  },

  -- File tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch  = "v3.x",
    cmd     = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        window     = { width = 30 },
        filesystem = {
          follow_current_file = { enabled = true },
          hide_dotfiles       = false,
          filtered_items = {
            visible         = true,
            hide_gitignored = false,
          },
        },
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    event  = { "BufReadPost", "BufNewFile" },
    main   = "ibl",
    config = function()
      require("ibl").setup({
        indent = { char = "│" },
        scope  = { enabled = true },
      })
    end,
  },

  -- Dashboard
  {
    "goolord/alpha-nvim",
    event        = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local alpha     = require("alpha")
      local dashboard = require("alpha.themes.dashboard")
      dashboard.section.header.val = {
        "                                                      ",
        "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
        "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
        "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
        "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
        "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
        "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
        "                                                      ",
      }
      dashboard.section.buttons.val = {
        dashboard.button("f", "  Find file",    ":Telescope find_files<CR>"),
        dashboard.button("e", "  New file",     ":ene <BAR> startinsert<CR>"),
        dashboard.button("r", "  Recent files", ":Telescope oldfiles<CR>"),
        dashboard.button("g", "  Live grep",    ":Telescope live_grep<CR>"),
        dashboard.button("c", "  Config",       ":e $MYVIMRC<CR>"),
        dashboard.button("l", "  Plugins",      ":Lazy<CR>"),
        dashboard.button("q", "  Quit",         ":qa<CR>"),
      }
      alpha.setup(dashboard.opts)
    end,
  },

  -- Notifications
  {
    "rcarriga/nvim-notify",
    event  = "VeryLazy",
    config = function()
      require("notify").setup({
        background_colour = "#1e1e2e",
        stages            = "fade_in_slide_out",
        timeout           = 3000,
      })
      vim.notify = require("notify")
    end,
  },

  { "nvim-tree/nvim-web-devicons", lazy = true },
}
