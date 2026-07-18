require("config.lazy")

local niri_zvim_adapter = vim.fn.stdpath("data") .. "/site/lua/niri-zvim"
if vim.fn.isdirectory(niri_zvim_adapter) == 1 then
  require("niri-zvim").setup()
end
