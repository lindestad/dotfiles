# Hyprlock lock screen

This setup uses Hyprlock as the preferred Niri lock screen when it is installed, with Noctalia's lock screen as the fallback on machines that do not have Hyprlock.

## Why

Noctalia v4's built-in lock screen worked for short fingerprint unlocks, but it got into a bad state after a longer lock and suspend/resume cycle: fprintd stopped scanning, the password field accepted no input, and logging out through GDM was the practical recovery path.

Hyprlock is a better fit for this machine because it supports password and fingerprint authentication as separate parallel methods. The password path can use Fedora's `password-auth` PAM stack, while Hyprlock talks to fprintd for fingerprint unlocks directly. That avoids mixing fingerprint auth into the same PAM conversation used for password entry.

## Files

- `config/hypr/hyprlock.conf`: synced Hyprlock appearance and auth config.
- `bin/niri-lock-screen`: portable lock wrapper used by Niri.
- `config/niri/keybinds.kdl`: binds `Super+Alt+L` to the wrapper.
- `scripts/install/desktop-niri.sh`: links the Hyprlock config and installs the wrapper when the Niri desktop option is selected.

## Behavior

The wrapper checks lock options in this order:

1. If `hyprlock` exists, run `hyprlock --immediate-render --no-fade-in`.
2. If Hyprlock is missing but Quickshell exists, call Noctalia's `lockScreen lock` IPC method.
3. If neither is available, ask `loginctl` to lock the session.

The wrapper also uses a non-blocking `flock` lock when available, so accidental repeated hotkey presses do not start multiple lockers.

## Hyprlock details

The config uses:

- `path = screenshot` for a blurred current-desktop background instead of a hard-coded wallpaper.
- Noctalia's current grayscale palette values for the lock surface, borders, and text.
- A single-line `$TIME` clock with separate date and user labels.
- `pam.module = password-auth` so the password unlock path stays password-only on Fedora.
- Hyprlock's native fingerprint block for fprintd.

The config intentionally avoids weather, media, and long-running shell widgets. A lock screen should be reliable first.

## Testing

Use the wrapper from an existing session:

```sh
~/.local/bin/niri-lock-screen
```

If you need verbose Hyprlock logs while testing:

```sh
hyprlock --verbose --immediate-render --no-fade-in
```

Hyprlock itself does not currently provide a dry-run config parser in the installed build, so the safe validation path is checking Niri config with `niri validate` and then testing the lock screen interactively.
