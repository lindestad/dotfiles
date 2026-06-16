return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          mason = false,
        },
        ty = {
          mason = false,
          settings = {
            ty = {
              diagnosticMode = "openFilesOnly",
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
              },
            },
          },
        },
      },
    },
  },
}
