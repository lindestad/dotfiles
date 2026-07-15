-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Auto-reload files changed on disk while Neovim is focused.
-- LazyVim already handles FocusGained/TermLeave; this catches changes
-- that happen while the cursor is idle inside the editor.
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = vim.api.nvim_create_augroup("auto_checktime", { clear = true }),
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

-- Let Niri navigate Neovim splits before falling through to Zellij or a window.
local niri_navigation_group = vim.api.nvim_create_augroup("niri_navigation", { clear = true })
local niri_navigation_file

_G.NiriNavigate = function(direction)
  local key = ({ left = "h", down = "j", up = "k", right = "l" })[direction]
  if not key then
    return false
  end

  local previous_window = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. key)
  return vim.api.nvim_get_current_win() ~= previous_window
end

if vim.env.NIRI_SOCKET and vim.v.servername ~= "" then
  local runtime_dir = vim.env.XDG_RUNTIME_DIR or "/tmp"
  niri_navigation_file = string.format("%s/niri-navigate.nvim.%d", runtime_dir, vim.fn.getpid())
  vim.fn.writefile({
    vim.v.servername,
    vim.env.ZELLIJ_SESSION_NAME or "",
    vim.env.ZELLIJ_PANE_ID or "",
  }, niri_navigation_file)
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = niri_navigation_group,
  callback = function()
    if niri_navigation_file then
      vim.fn.delete(niri_navigation_file)
    end
  end,
})
