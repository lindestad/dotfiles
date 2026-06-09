-- Format and save: Ctrl-s
vim.keymap.set({ "n", "i" }, "<C-s>", function()
  pcall(vim.lsp.buf.format, { async = false })
  vim.cmd("write")
end, { desc = "Save file" })

-- Save without formatting: Ctrl-Shift-s
vim.keymap.set({ "n", "i" }, "<C-S-s>", function()
  vim.cmd("noautocmd write")
end, { desc = "Save without formatting" })

-- Quit with Shift-Tab
vim.keymap.set("n", "<S-Tab>", function()
  if vim.bo.modified then
    print("Unsaved changes!")
  else
    vim.cmd("quit")
  end
end)

-- Clipboard yanks/pastes with leader shortcuts
vim.keymap.set({ "n", "v" }, "<leader>y", "+y", { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>p", "+p", { desc = "Paste from system clipboard" })
