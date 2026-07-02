return {
  -- Theme pack: adds many base16-* colorschemes to the picker.
  { "RRethy/base16-nvim", lazy = true },

  -- Curated Neovim colorscheme plugins from active GitHub repos.
  { "rebelot/kanagawa.nvim", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "EdenEast/nightfox.nvim", lazy = true },
  { "ellisonleao/gruvbox.nvim", lazy = true },
  { "projekt0n/github-nvim-theme", lazy = true },
  { "Mofiqul/vscode.nvim", lazy = true },
  { "olimorris/onedarkpro.nvim", lazy = true },
  { "navarasu/onedark.nvim", lazy = true },
  { "marko-cerovac/material.nvim", lazy = true },
  { "AlexvZyl/nordic.nvim", lazy = true },
  { "neanias/everforest-nvim", lazy = true },
  { "savq/melange-nvim", lazy = true },
  {
    "Shatur/neovim-ayu",
    priority = 1000,
    opts = {
      mirage = false,
      terminal = true,
    },
    config = function(_, opts)
      require("ayu").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ayu-dark",
    },
  },
  { "rmehri01/onenord.nvim", lazy = true },
  { "loctvl842/monokai-pro.nvim", lazy = true },
  { "scottmckendry/cyberdream.nvim", lazy = true },
  { "vague-theme/vague.nvim", lazy = true },
  { "zenbones-theme/zenbones.nvim", dependencies = { "rktjmp/lush.nvim" }, lazy = true },
  { "slugbyte/lackluster.nvim", lazy = true },
  { "olivercederborg/poimandres.nvim", lazy = true },
  { "ribru17/bamboo.nvim", lazy = true },
  { "dgox16/oldworld.nvim", lazy = true },
  { "miikanissi/modus-themes.nvim", lazy = true },
  { "aktersnurra/no-clown-fiesta.nvim", lazy = true },
  { "thesimonho/kanagawa-paper.nvim", lazy = true },
  { "maxmx03/fluoromachine.nvim", lazy = true },
  { "oxfist/night-owl.nvim", lazy = true },
  { "zootedb0t/citruszest.nvim", lazy = true },
  { "datsfilipe/vesper.nvim", lazy = true },
  { "dasupradyumna/midnight.nvim", lazy = true },
}
