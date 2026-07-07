local uv = vim.uv or vim.loop

local function should_open_startup_explorer()
  if vim.fn.argc(-1) ~= 0 then
    return false
  end

  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  local ft = vim.bo[buf].filetype

  return (name == "" or ft == "snacks_dashboard") and not vim.bo[buf].modified
end

local function startup_explorer_opts()
  return {
    cwd = uv.cwd(),
    hidden = true,
    ignored = true,
    exclude = { ".git" },
    jump = { close = true },
    layout = {
      fullscreen = true,
      hidden = { "preview" },
      layout = {
        box = "vertical",
        backdrop = false,
        width = 0,
        height = 0,
        border = "none",
        title = "{title} {live} {flags}",
        title_pos = "left",
        { win = "input", height = 1, border = "bottom" },
        { win = "list", border = "none" },
      },
    },
  }
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
            ignored = true,
            exclude = { ".git" },
            jump = { close = true },
          },
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("startup_explorer", { clear = true }),
        callback = function()
          if should_open_startup_explorer() then
            vim.schedule(function()
              if should_open_startup_explorer() then
                Snacks.explorer(startup_explorer_opts())
              end
            end)
          end
        end,
      })
    end,
  },
}
