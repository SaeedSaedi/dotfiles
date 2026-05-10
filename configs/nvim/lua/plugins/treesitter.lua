return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build  = ":TSUpdate",
    event  = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "python", "go", "gomod", "gosum", "gowork",
          "php", "phpdoc",
          "lua", "vim", "vimdoc", "query",
          "bash", "json", "json5", "yaml", "toml",
          "markdown", "markdown_inline",
          "html", "css", "javascript", "typescript", "tsx",
          "dockerfile", "sql", "regex", "comment",
          "gitignore", "gitcommit",
        },
        auto_install = true,
        highlight    = { enable = true },
        indent       = { enable = true },
        textobjects = {
          select = {
            enable    = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable    = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
          },
          swap = {
            enable        = true,
            swap_next     = { ["<leader>sp"] = "@parameter.inner" },
            swap_previous = { ["<leader>sP"] = "@parameter.inner" },
          },
        },
      })
    end,
  },
}
