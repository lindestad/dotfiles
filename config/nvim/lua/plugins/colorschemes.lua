return {
  {
    "Shatur/neovim-ayu",
    priority = 1000,
    opts = {
      mirage = false,
      terminal = true,
    },
    config = function(_, opts) require("ayu").setup(opts) end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-dark",
    },
  },
  { "folke/tokyonight.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
}
