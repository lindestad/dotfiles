# Noctalia v5

The shared Niri configuration starts `noctalia` and uses its `noctalia msg`
commands. Install the `noctalia` package, rather than the legacy
`noctalia-shell` package. The installer uses the Arch/CachyOS repositories,
Fedora 44+ repositories, or the Noctalia APT repository on Debian trixie/sid
and Ubuntu 26.04.

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

Run `noctalia config validate` and `niri validate` after editing. The log is
`~/.cache/noctalia/noctalia.log`. Open settings with `Mod+Shift+Comma`.
