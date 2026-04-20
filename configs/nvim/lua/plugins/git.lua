return {
  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    event  = { "BufReadPost", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "" },
          topdelete    = { text = "" },
          changedelete = { text = "▎" },
          untracked    = { text = "▎" },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          local function map(mode, l, r, desc)
            vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
          end
          map("n", "]g",         gs.next_hunk,                        "Next Hunk")
          map("n", "[g",         gs.prev_hunk,                        "Prev Hunk")
          map("n", "<leader>gs", gs.stage_hunk,                       "Stage Hunk")
          map("n", "<leader>gr", gs.reset_hunk,                       "Reset Hunk")
          map("n", "<leader>gS", gs.stage_buffer,                     "Stage Buffer")
          map("n", "<leader>gp", gs.preview_hunk,                     "Preview Hunk")
          map("n", "<leader>gb", gs.blame_line,                       "Blame Line")
          map("n", "<leader>gB", gs.toggle_current_line_blame,        "Toggle Blame")
          map("n", "<leader>gd", gs.diffthis,                         "Diff This")
          map("n", "<leader>gD", function() gs.diffthis("~") end,     "Diff HEAD~")
          map("n", "<leader>gR", gs.reset_buffer,                     "Reset Buffer")
        end,
      })
    end,
  },

  -- LazyGit TUI
  {
    "kdheepak/lazygit.nvim",
    cmd          = "LazyGit",
    keys         = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
