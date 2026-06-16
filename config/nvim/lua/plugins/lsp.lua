return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ty = {
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
