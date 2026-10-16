# Noctalia v5

The shared Niri configuration starts `noctalia` and uses its `noctalia msg`
commands. Install the `noctalia` package, rather than the legacy
`noctalia-shell` package, and remove the legacy QuickShell stack if it is still
present (`noctalia-shell`, `noctalia-qs`, `quickshell`). The installer uses the
Arch/CachyOS repositories, Fedora 44+ repositories, or the Noctalia APT
repository on Debian trixie/sid and Ubuntu 26.04.

`config/noctalia/config.toml` supplies the solid, edge-aligned grayscale bar,
widgets, idle timers, and session actions. The palette is linked into
`~/.config/noctalia/palettes/monochrome-strong.json`.

Settings changed through the UI are stored in
`~/.local/state/noctalia/settings.toml` and override the shared base config.
V4's `settings.json` and plugins are separate and are not imported by v5.

Put machine-specific monitor settings in `~/.config/noctalia/monitors.toml`.
For an auto-hide bar that lets windows occupy the space beneath it:

```toml
[bar.default.monitor."DP-3"]
auto_hide = true
reserve_space = false
```

## Brightness

Kernel backlight devices are used when present, and external monitors are driven
over DDC/CI, which needs the `ddcutil` package. Enable that path in
`config/noctalia/config.toml`:

```toml
[brightness]
enable_ddcutil = true
minimum_brightness = 0.05
```

`minimum_brightness` is a 0.0 to 1.0 floor, so a stray keypress cannot take a
panel to black. The Niri keybinds call `noctalia msg brightness-up` and
`brightness-down` rather than calling a brightness tool directly, so one set of
keys covers both backends and Noctalia draws its own OSD.

Noctalia maps connectors to I2C buses by matching `ddcutil detect` output.
Monitors that share an EDID cannot be told apart that way, and then the bus has
to be pinned in `~/.config/noctalia/monitors.toml`:

```toml
[brightness.monitor."DP-3"]
ddc_bus = 4
```

Discovery results land in `~/.cache/noctalia/noctalia.log` as
`found ddcutil display connector=DP-3 bus=/dev/i2c-4 current=65%`. After
plugging a monitor in, use Control Center → Monitor → Rescan DDC/CI monitors.
`ddcutil setvcp 10 <value>` only takes an absolute value, and it reads `+10` as
`0`, so step brightness through the shell instead of the raw tool.

Run `noctalia config validate` and `niri validate` after editing. The log is
`~/.cache/noctalia/noctalia.log`. Open settings with `Mod+Shift+Comma`.
