return {
  -- LSP server installer
  {
    "williamboman/mason.nvim",
    cmd   = "Mason",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons  = {
            package_installed   = "✓",
            package_pending     = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  -- Bridge mason <-> lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "pyright",      -- Python
          "gopls",        -- Go
          "intelephense", -- PHP
          "lua_ls",       -- Lua (for editing this config)
        },
        automatic_installation = true,
      })
    end,
  },

  -- Core LSP config
  {
    "neovim/nvim-lspconfig",
    event        = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local lspconfig    = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local on_attach = function(_, bufnr)
        local b = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "K",          vim.lsp.buf.hover,           b)
        vim.keymap.set("n", "gd",         vim.lsp.buf.definition,      b)
        vim.keymap.set("n", "gD",         vim.lsp.buf.declaration,     b)
        vim.keymap.set("n", "gr",         vim.lsp.buf.references,      b)
        vim.keymap.set("n", "gi",         vim.lsp.buf.implementation,  b)
        vim.keymap.set("n", "gy",         vim.lsp.buf.type_definition, b)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,          b)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,     b)
        vim.keymap.set("n", "<leader>lf", function()
          vim.lsp.buf.format({ async = true })
        end, b)
        vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, b)
      end

      -- Diagnostic appearance
      vim.diagnostic.config({
        virtual_text     = { prefix = "●" },
        signs            = true,
        underline        = true,
        update_in_insert = false,
        severity_sort    = true,
        float            = { border = "rounded", source = "always" },
      })

      local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Python
      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach    = on_attach,
        settings = {
          python = {
            analysis = {
              typeCheckingMode       = "basic",
              autoSearchPaths        = true,
              useLibraryCodeForTypes = true,
              diagnosticMode         = "workspace",
            },
          },
        },
      })

      -- Go
      lspconfig.gopls.setup({
        capabilities = capabilities,
        on_attach    = on_attach,
        settings = {
          gopls = {
            analyses           = { unusedparams = true, shadow = true },
            staticcheck        = true,
            gofumpt            = true,
            completeUnimported = true,
          },
        },
      })

      -- PHP
      lspconfig.intelephense.setup({
        capabilities = capabilities,
        on_attach    = on_attach,
        settings = {
          intelephense = {
            files = { maxSize = 5000000 },
          },
        },
      })

      -- Lua (for editing nvim config)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach    = on_attach,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace   = { checkThirdParty = false },
            telemetry   = { enable = false },
          },
        },
      })
    end,
  },

  -- Better LSP UI
  {
    "nvimdev/lspsaga.nvim",
    event        = "LspAttach",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "gh",         "<cmd>Lspsaga finder<CR>",               desc = "LSP Finder" },
      { "<leader>pd", "<cmd>Lspsaga peek_definition<CR>",      desc = "Peek Definition" },
      { "<leader>pt", "<cmd>Lspsaga peek_type_definition<CR>", desc = "Peek Type" },
      { "<leader>ol", "<cmd>Lspsaga outline<CR>",              desc = "Code Outline" },
      { "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>",       desc = "Incoming Calls" },
      { "<leader>co", "<cmd>Lspsaga outgoing_calls<CR>",       desc = "Outgoing Calls" },
    },
    config = function()
      require("lspsaga").setup({
        ui             = { border = "rounded" },
        symbol_in_winbar = { enable = true },
      })
    end,
  },
}
