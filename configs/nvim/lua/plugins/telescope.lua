return {
  {
    "nvim-telescope/telescope.nvim",
    cmd     = "Telescope",
    version = false,
    keys = {
      { "<leader>ff",  "<cmd>Telescope find_files<cr>",            desc = "Find Files" },
      { "<leader>fg",  "<cmd>Telescope live_grep<cr>",             desc = "Live Grep" },
      { "<leader>fb",  "<cmd>Telescope buffers<cr>",               desc = "Buffers" },
      { "<leader>fh",  "<cmd>Telescope help_tags<cr>",             desc = "Help Tags" },
      { "<leader>fr",  "<cmd>Telescope oldfiles<cr>",              desc = "Recent Files" },
      { "<leader>fc",  "<cmd>Telescope git_commits<cr>",           desc = "Git Commits" },
      { "<leader>fs",  "<cmd>Telescope lsp_document_symbols<cr>",  desc = "Doc Symbols" },
      { "<leader>fw",  "<cmd>Telescope lsp_workspace_symbols<cr>", desc = "WS Symbols" },
      { "<leader>fd",  "<cmd>Telescope diagnostics<cr>",           desc = "Diagnostics" },
      { "<leader>fk",  "<cmd>Telescope keymaps<cr>",               desc = "Keymaps" },
      { "<leader>f.",  "<cmd>Telescope resume<cr>",                desc = "Resume Last" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond  = function() return vim.fn.executable("make") == 1 end,
      },
    },
    config = function()
      local telescope = require("telescope")
      local actions   = require("telescope.actions")

      telescope.setup({
        defaults = {
          prompt_prefix   = " ",
          selection_caret = " ",
          path_display    = { "smart" },
          file_ignore_patterns = {
            "node_modules", ".git/", "vendor/", "__pycache__",
            "%.pyc", "%.class", "%.o",
          },
          mappings = {
            i = {
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
              ["<Esc>"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = { hidden = true },
          live_grep  = { additional_args = { "--hidden" } },
        },
      })

      pcall(telescope.load_extension, "fzf")
    end,
  },
}
