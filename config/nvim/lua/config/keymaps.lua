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
vim.keymap.set({ "n", "i" }, "<S-Tab>", function()
  if vim.bo.modified then
    print("Unsaved changes!")
  else
    vim.cmd("quit")
  end
end, { desc = "Quit" })

-- Force quit with Ctrl-Shift-Tab
vim.keymap.set({ "n", "i" }, "<C-S-Tab>", "<Cmd>quit!<CR>", { desc = "Force quit" })

-- Clipboard yanks/pastes with leader shortcuts
vim.keymap.set({ "n", "x" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", [["+p]], { desc = "Paste from system clipboard" })

vim.keymap.set("n", "<leader>a", "GVgg", { desc = "Select all" })
vim.keymap.set("n", "<leader>Y", function()
  local view = vim.fn.winsaveview()
  vim.cmd([[silent %yank +]])
  vim.fn.winrestview(view)
end, { desc = "Copy buffer to system clipboard" })

vim.keymap.set("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New buffer" })

-- Line navigation
vim.keymap.set({ "n", "v" }, "gh", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "v" }, "gl", "$", { desc = "End of line" })

-- Indent in visual mode (re-select after)
vim.keymap.set("x", "<Tab>", ">gv", { desc = "Indent right" })
vim.keymap.set("x", "<S-Tab>", "<gv", { desc = "Indent left" })

-- Toggle comments with Ctrl-/
pcall(vim.keymap.del, "t", "<C-/>")
pcall(vim.keymap.del, { "n", "t" }, "<C-_>")
vim.keymap.set("n", "<C-/>", "gcc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("x", "<C-/>", "gc", { remap = true, desc = "Toggle comment" })
vim.keymap.set("i", "<C-/>", "<C-o>gcc", { remap = true, desc = "Toggle comment" })

-- Insert mode navigation / editing
vim.keymap.set("i", "<C-h>", "<Left>", { desc = "Move left" })
vim.keymap.set("i", "<C-j>", "<Down>", { desc = "Move down" })
vim.keymap.set("i", "<C-k>", "<Up>", { desc = "Move up" })
vim.keymap.set("i", "<C-l>", "<Right>", { desc = "Move right" })
vim.keymap.set("i", "<C-BS>", "<C-w>", { desc = "Delete previous word" })

-- Shift-U: redo (reverse undo). Default U (restore line) is rarely useful.
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })

local function root_terminal()
  Snacks.terminal.focus(nil, { cwd = LazyVim.root() })
end

vim.keymap.set({ "n", "t" }, "<C-;>", root_terminal, { desc = "Terminal (Root Dir)" })
