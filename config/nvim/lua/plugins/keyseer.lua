return {
  {
    "jokajak/keyseer.nvim",
    cmd = "KeySeer",
    keys = {
      { "<leader>uk", "<cmd>KeySeer<cr>", desc = "Keymap keyboard" },
    },
    opts = {
      include_builtin_keymaps = true,
      include_global_keymaps = true,
      include_buffer_keymaps = true,
    },
  },
}
