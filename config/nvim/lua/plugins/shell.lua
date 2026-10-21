return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        bashls = {},
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        zsh = { "shellcheck" },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      -- shfmt formatting is already enabled by LazyVim defaults
      ensure_installed = { "shellcheck" },
    },
  },
}
