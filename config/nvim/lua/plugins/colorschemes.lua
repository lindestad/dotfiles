return {
  -- Theme pack: adds many base16-* colorschemes to the picker.
  { "RRethy/base16-nvim" },

  -- Curated Neovim colorscheme plugins from active GitHub repos.
  { "rebelot/kanagawa.nvim" },
  { "rose-pine/neovim", name = "rose-pine" },
  { "EdenEast/nightfox.nvim" },
  { "ellisonleao/gruvbox.nvim" },
  { "projekt0n/github-nvim-theme" },
  { "Mofiqul/vscode.nvim" },
  { "olimorris/onedarkpro.nvim" },
  { "navarasu/onedark.nvim" },
  { "marko-cerovac/material.nvim" },
  { "AlexvZyl/nordic.nvim" },
  { "neanias/everforest-nvim" },
  { "savq/melange-nvim" },
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
  { "rmehri01/onenord.nvim" },
  { "loctvl842/monokai-pro.nvim" },
  { "scottmckendry/cyberdream.nvim" },
  { "vague-theme/vague.nvim" },
  { "zenbones-theme/zenbones.nvim", dependencies = { "rktjmp/lush.nvim" } },
  { "slugbyte/lackluster.nvim" },
  { "olivercederborg/poimandres.nvim" },
  { "ribru17/bamboo.nvim" },
  { "dgox16/oldworld.nvim" },
  { "miikanissi/modus-themes.nvim" },
  { "aktersnurra/no-clown-fiesta.nvim" },
  { "thesimonho/kanagawa-paper.nvim" },
  { "maxmx03/fluoromachine.nvim" },
  { "oxfist/night-owl.nvim" },
  { "zootedb0t/citruszest.nvim" },
  { "datsfilipe/vesper.nvim" },
  { "dasupradyumna/midnight.nvim" },
}
