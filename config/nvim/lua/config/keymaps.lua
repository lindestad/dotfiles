-- Format and save: Ctrl-s
vim.keymap.set({ "n", "i" }, "<C-s>", "<cmd>write<cr>", { desc = "Format and save file" })

-- Save without formatting: Ctrl-Shift-s
vim.keymap.set({ "n", "i" }, "<C-S-s>", function()
  local buf = vim.api.nvim_get_current_buf()
  local autoformat = vim.b[buf].autoformat
  vim.b[buf].autoformat = false

  local ok, err = pcall(vim.cmd.write)
  vim.b[buf].autoformat = autoformat

  if not ok then
    error(err, 0)
  end
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
vim.keymap.set({ "n", "x" }, "h", "<BS>", { desc = "Left with line wrap" })
vim.keymap.set({ "n", "x" }, "l", "<Space>", { desc = "Right with line wrap" })

-- Keep Ctrl-j/k for multicursor and use Alt-h/j/k/l as the complete split-navigation set.
pcall(vim.keymap.del, "n", "<C-h>")
pcall(vim.keymap.del, "n", "<C-l>")
vim.keymap.set("n", "<M-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
vim.keymap.set("n", "<M-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
vim.keymap.set("n", "<M-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
vim.keymap.set("n", "<M-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })

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

-- Preserve LazyVim's Escape cleanup while giving multicursor first refusal.
vim.keymap.set("n", "<Esc>", function()
  local mc = package.loaded["multicursor-nvim"]
  if mc and mc.hasCursors() then
    mc.clearCursors()
    return ""
  end

  vim.cmd("nohlsearch")
  LazyVim.cmp.actions.snippet_stop()
  return "<Esc>"
end, { expr = true, desc = "Clear cursors / Escape" })

local function root_terminal() Snacks.terminal.focus(nil, { cwd = LazyVim.root() }) end

vim.keymap.set({ "n", "t" }, "<C-;>", root_terminal, { desc = "Terminal (Root Dir)" })
