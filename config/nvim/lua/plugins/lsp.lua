return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            { "<c-k>", false, mode = "i" },
          },
        },
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
