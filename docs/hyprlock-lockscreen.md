# Hyprlock lock screen

This setup uses Hyprlock as the preferred Niri lock screen when it is installed, with Noctalia's lock screen as the fallback on machines that do not have Hyprlock.

## Why

Noctalia v4's built-in lock screen worked for short fingerprint unlocks, but it got into a bad state after a longer lock and suspend/resume cycle: fprintd stopped scanning, the password field accepted no input, and logging out through GDM was the practical recovery path.

Hyprlock is a better fit for this machine because it supports password and fingerprint authentication as separate parallel methods. The password path can use Fedora's `password-auth` PAM stack, while Hyprlock talks to fprintd for fingerprint unlocks directly. That avoids mixing fingerprint auth into the same PAM conversation used for password entry.

## Files

- `config/hypr/hyprlock.conf`: synced Hyprlock appearance and auth config.
- `~/.config/hypr/hyprlock.local.conf`: untracked per-host overrides, created
  once by the installer; `niri-lock-screen` selects it with `--config`.
- `bin/niri-lock-screen`: portable lock wrapper used by Niri and Noctalia's lock action.
- `bin/niri-lock-and-suspend`: starts the lock wrapper, waits for Niri to confirm
  the session is fully locked through logind's `LockedHint`, and only then suspends.
- `config/niri/keybinds.kdl`: binds `Super+Alt+L` to the wrapper.
- `scripts/install/desktop-niri.sh`: links the Hyprlock config and installs the wrapper when the Niri desktop option is selected.

## Behavior

The wrapper checks lock options in this order:

1. If `hyprlock` exists and `~/.config/hypr/hyprlock.local.conf` is present,
   run `hyprlock --config <that file> --immediate-render --no-fade-in`.
2. If Hyprlock exists but has no local config, run `hyprlock --immediate-render --no-fade-in`.
3. If Hyprlock is missing, call Noctalia v5 with `noctalia msg session lock`.
4. If neither is available, ask `loginctl` to lock the session.

The wrapper also uses a non-blocking `flock` lock when available, so accidental repeated hotkey presses do not start multiple lockers.

Noctalia's session-menu lock action should call `niri-lock-screen`, and its suspend
action should call `niri-lock-and-suspend` through the command overrides in `config/noctalia/config.toml`.
The suspend helper performs the lock itself and will fail closed instead of
suspending if Niri does not confirm the session lock within ten seconds. It uses
the same portable lock wrapper, so systems without Hyprlock retain Noctalia's
fallback locker.

On this Fedora laptop, ignored `config/niri/local.kdl` sets
`NOCTALIA_PAM_SERVICE=password-auth` after verifying that it is a password-only
stack. The shared config does not set a PAM service because other hosts may have a
different PAM layout.

## Hyprlock details

The config uses:

- `path = screenshot` for a blurred current-desktop background instead of a hard-coded wallpaper.
- Noctalia's current grayscale palette values for the lock surface, borders, and text.
- A single-line `$TIME` clock with separate date and user labels.
- `pam.module = password-auth` so the password unlock path stays password-only on Fedora.
- Hyprlock's native fingerprint block for fprintd.

The config intentionally avoids weather, media, and long-running shell widgets. A lock screen should be reliable first.

## Per-host PAM tweak

`password-auth` is Fedora naming and does not exist on Arch/CachyOS, so the
shared `pam.module` would break password unlocks on other distros. On first run
the installer creates `~/.config/hypr/hyprlock.local.conf`: it sources the
shared config and then reopens `auth { pam { module = ... } }` with the first
stack found in `/etc/pam.d/` — `password-auth` (Fedora), `system-login`
(Arch/CachyOS), `system-auth`, or `login`. The lock wrapper passes that file to
hyprlock with `--config`, so the host value wins by being assigned after the
sourced one. The file is host-specific and the installer never overwrites it;
delete it to have it regenerated.

The override direction matters: hyprlock's `source =` keyword errors when the
target file does not exist (even for non-matching globs), so the optional
per-host file sources the always-present shared config, and the wrapper opts
in only when the local file exists. Never put an unconditional `source =` of a
per-host file into the shared config.

## Testing

Use the wrapper from an existing session:

```sh
~/.local/bin/niri-lock-screen
```

To exercise the coordinated suspend path:

```sh
~/.local/bin/niri-lock-and-suspend
```

If you need verbose Hyprlock logs while testing:

```sh
hyprlock --verbose --immediate-render --no-fade-in
```

Hyprlock itself does not currently provide a dry-run config parser in the installed build, so the safe validation path is checking Niri config with `niri validate` and then testing the lock screen interactively.
