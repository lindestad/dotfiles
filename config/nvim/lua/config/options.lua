-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.wrap = true
vim.opt.timeoutlen = 2000

-- Use ty as LazyVim's Python language server.
vim.g.lazyvim_python_lsp = "ty"
