# Lock screen notes

## Sources and inspiration

These examples influenced the Hyprlock layout:

- JaKooLit Hyprland-Dots: https://github.com/JaKooLit/Hyprland-Dots/blob/main/config%2Fhypr%2Fhyprlock.conf
- Hyprlock-Dots layout collection: https://github.com/mahaveergurjar/Hyprlock-Dots
- Catppuccin Hyprlock theme: https://github.com/catppuccin/hyprlock
- Official Hyprlock docs: https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/

Common patterns in polished Hyprlock configs:

- Blurred wallpaper or screenshot background.
- Large clock as the visual anchor.
- Small date/user/context labels.
- Compact password input near the center.
- Keyboard layout, battery, weather, or status labels near the lower edge.
- Sourceable color variables rather than one-off color literals everywhere.

For this setup, the extra status widgets were kept minimal. The previous problem was a lock/unlock reliability issue, so the design uses the common visual structure without adding optional moving parts.

## Noctalia v4 interaction

The Niri hotkey no longer calls Noctalia's lock screen directly. It calls `niri-lock-screen`, which prefers Hyprlock when installed.

Noctalia still has internal lock paths:

- Session menu lock action.
- Idle lock action.
- Lock-before-suspend action when `general.lockOnSuspend` is enabled.

The live session-menu configuration routes lock to `niri-lock-screen` and suspend
to `niri-lock-and-suspend`. `general.lockOnSuspend` is disabled because the suspend
wrapper owns both operations and waits for Niri's fully-locked signal before sleep.

Noctalia's idle lock path currently executes the configured idle lock command and
then still activates the Noctalia lock panel. Idle handling remains disabled in
the live configuration.

As a fallback guardrail on this Fedora laptop, ignored `config/niri/local.kdl`
sets `NOCTALIA_PAM_SERVICE=password-auth`, and Noctalia's
`general.allowPasswordWithFprintd` setting is disabled. This prevents its internal
locker from spawning the `fprintd-verify` sensor-occupancy workaround. The shared
config makes no PAM-service assumption for other hosts.

## Auth model

The working setup is:

```hyprlang
auth {
    pam {
        module = password-auth
    }

    fingerprint {
        enabled = true
        ready_message = Scan fingerprint to unlock
        present_message = Scanning...
        retry_delay = 250
    }
}
```

On this Fedora machine, `password-auth` keeps the typed password path clean. Hyprlock's fingerprint block handles fprintd separately, so a fprintd stall is less likely to poison password entry.

If another distro's `password-auth` does not exist, adjust `auth.pam.module` to that distro's password-only PAM service. Keep fingerprint out of that PAM service unless there is a clear reason to combine them.
