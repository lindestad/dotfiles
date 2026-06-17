local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.window_decorations = "NONE"
config.window_padding = {
  left = 10,
  right = 10,
  top = 20,
  bottom = 20,
}

config.enable_tab_bar = false
config.font_size = 13
config.font = wezterm.font("MonaspiceNe Nerd Font", { weight = "Regular" })
config.font_rules = {
  {
    intensity = "Bold",
    italic = false,
    font = wezterm.font("MonaspiceNe Nerd Font", { weight = "Bold" }),
  },
  {
    intensity = "Normal",
    italic = true,
    font = wezterm.font("MonaspiceNe Nerd Font", { italic = true }),
  },
  {
    intensity = "Bold",
    italic = true,
    font = wezterm.font("MonaspiceNe Nerd Font", { weight = "Bold", italic = true }),
  },
}

config.harfbuzz_features = {
  "calt=1",
  "liga=1",
  "dlig=1",
  "ss01=1",
  "ss02=1",
  "ss03=1",
  "ss04=1",
  "ss05=1",
  "ss06=1",
  "ss07=1",
  "ss08=1",
  "ss09=1",
  "ss10=1",
}

config.default_prog = { "/usr/bin/zsh", "-l" }
config.enable_kitty_keyboard = true

config.colors = {
  foreground = "#bfbdb6",
  background = "#020305",

  cursor_fg = "#0b0e14",
  cursor_bg = "#bfbdb6",
  cursor_border = "#bfbdb6",

  selection_fg = "#bfbdb6",
  selection_bg = "#1b3a5b",

  ansi = {
    "#101317",
    "#d91a25",
    "#47cc1d",
    "#f9af4f",
    "#229be0",
    "#9e43fa",
    "#67e0d6",
    "#c7c7c7",
  },
  brights = {
    "#686868",
    "#f07178",
    "#aad94c",
    "#ffb454",
    "#59c2ff",
    "#d2a6ff",
    "#95e6cb",
    "#ffffff",
  },
}

return config
