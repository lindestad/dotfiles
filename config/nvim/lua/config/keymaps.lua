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
vim.keymap.set({ "n", "x" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", [["+p]], { desc = "Paste from system clipboard" })

vim.keymap.set("n", "<leader>a", "GVgg", { desc = "Select all" })
vim.keymap.set("n", "<leader>Y", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[silent %yank +]])
  vim.fn.winrestview(view)
end, { desc = "Copy buffer to system clipboard" })

-- Line navigation
vim.keymap.set({ "n", "v" }, "g-h", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "v" }, "g-l", "$", { desc = "End of line" })

-- Shift-U: redo (reverse undo). Default U (restore line) is rarely useful.
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

local function root_terminal()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end

vim.keymap.set({ "n", "t" }, "<C-/>", root_terminal, { desc = "Terminal (Root Dir)" })
vim.keymap.set({ "n", "t" }, "<C-S-/>", root_terminal, { desc = "which_key_ignore" })
vim.keymap.set({ "n", "t" }, "<C-_>", root_terminal, { desc = "which_key_ignore" })
vim.keymap.set({ "n", "t" }, "<C-7>", root_terminal, { desc = "which_key_ignore" })
vim.keymap.set({ "n", "t" }, "<C-S-7>", root_terminal, { desc = "which_key_ignore" })
