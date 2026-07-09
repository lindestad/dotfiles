# Plymouth LUKS Theme

This setup uses the `hexagon_alt` animation assets from a pinned fork of
`adi1090x/plymouth-themes` for the graphical LUKS unlock prompt on CachyOS.

The installed theme is generated locally as `hexagon_alt_twostep`. It uses
Plymouth's script plugin so the hexagon animation stays visible while the LUKS
password prompt is shown. The script uses the primary Plymouth display for all
layout math and draws a small custom prompt below the animation.

## Install

Run from the repo root:

```sh
sudo ./scripts/install/plymouth-luks-theme.sh
```

The helper prints the detected boot path and Secure Boot/Limine refresh plan,
then asks for confirmation before it installs files or rebuilds boot images.
For non-interactive use:

```sh
sudo ./scripts/install/plymouth-luks-theme.sh --yes
```

The optional first argument sets Plymouth's integer `DeviceScale`. By default,
the helper leaves `DeviceScale` unset and lets Plymouth choose automatically:

```sh
sudo ./scripts/install/plymouth-luks-theme.sh 2
```

The helper:

- fetches only `pack_2/hexagon_alt` from
  `https://github.com/lindestad/plymouth-themes.git`;
- pins the source checkout to commit
  `5d8817458d764bff4ff9daae94cf1bbaabf16ede`;
- installs the generated theme to
  `/usr/share/plymouth/themes/hexagon_alt_twostep`;
- writes script theme metadata around the hexagon animation assets;
- keeps the upstream `progress-*.png` hexagon frames and validates that the
  pinned source still has the expected 119 animation frames;
- copies Plymouth's stock prompt assets from the installed `spinner` theme:
  `bullet.png` for typed password dots and `capslock.png` for the Caps Lock
  warning;
- declares `Noto Sans` / `Noto Sans Mono` in the generated metadata so the
  mkinitcpio Plymouth hook packs those fonts into the initramfs;
- writes `/etc/plymouth/plymouthd.conf` with `Theme=hexagon_alt_twostep` and
  only writes `DeviceScale=` when a scale argument is provided;
- rebuilds boot images with `limine-mkinitcpio` when available, otherwise
  falls back to `mkinitcpio -P`;
- on Limine systems, runs `limine-snapper-sync` and `limine-snapper-info` when
  available;
- when Secure Boot, Limine verification, or Limine config enrollment appears to
  be active and the Secure Boot refresh helper is installed, runs
  `refresh-limine-secureboot-assets --refresh-assets-only` after rebuilding.
  That refreshes Limine file hashes, enrolls the Limine config checksum,
  refreshes the Limine fallback EFI when applicable, signs the Limine EFI
  through `limine-enroll-config`/`sbctl` when configured, and verifies hashes.

If Limine verification or Secure Boot appears to be enabled but the refresh
helper is not installed, the script warns before proceeding. The managed setup
for that helper is documented in
[secureboot-limine-signing.md](./secureboot-limine-signing.md).

## Requirements

The mkinitcpio config must include the `plymouth` hook before `sd-encrypt`.
The kernel command line must include `splash`.

Plymouth needs a font in the initramfs for prompt labels and console text. This
theme uses `Noto Sans` and `Noto Sans Mono` for text. Password dots are drawn
from Plymouth's stock `bullet.png`, so they do not depend on a special glyph in
the prompt font. On CachyOS/Arch, keep `noto-fonts` installed:

```sh
pacman -Q noto-fonts
```

Fonts are not copied manually into `/boot`. The mkinitcpio Plymouth hook
resolves fonts with `fc-match` and packs them into the generated initramfs.

## Source and License

The upstream theme assets are GPLv3 and remain in their upstream fork instead
of being vendored into this MIT-licensed dotfiles repository. The installer
uses a pinned commit from the fork for reproducibility and generates local
Plymouth metadata at install time.

## Layout Notes

The stock CachyOS LUKS prompt is a `two-step` Plymouth theme. Its C plugin
creates a separate view per pixel display and computes prompt placement from
that display's own width and height. That is why the default LUKS prompt centers
correctly.

The upstream `hexagon_alt` theme is a script theme with one global sprite
coordinate space. Its original script mixed `Window.GetWidth(0)` /
`Window.GetHeight(0)` with unindexed `Window.GetX()` / `Window.GetY()`, which
can center the prompt against the wrong display bounds on multi-display boots.

The generated script uses `Window.GetX(0)`, `Window.GetY(0)`,
`Window.GetWidth(0)`, and `Window.GetHeight(0)` consistently. The hexagon is
centered on display 0 at 42% of the display height, and the prompt is drawn
below it.

Plymouth's stock `two-step` plugin cannot keep the animation visible during
password entry. Its password callback stops the animation, and its password draw
path only draws the prompt widgets. This is why the installer uses the script
plugin instead of trying to combine `two-step` with the hexagon animation.

## Caps Lock

The stock `two-step` prompt shows Caps Lock by using Plymouth's internal
`ply-capslock-icon` helper. Script themes cannot reuse that helper directly,
but Plymouth exposes `Plymouth.GetCapslockState()` to scripts. The generated
theme polls that state during refresh and shows the stock `capslock.png` below
the password dots when Caps Lock is active.

## Manual Equivalent

The installer is the canonical manual recipe. In outline, it fetches the pinned
`pack_2/hexagon_alt` source, copies it to
`/usr/share/plymouth/themes/hexagon_alt_twostep`, adds `bullet.png` and
`capslock.png` from Plymouth's spinner theme, writes a generated
`hexagon_alt_twostep.script`, writes metadata with `ModuleName=script`, sets
`Theme=hexagon_alt_twostep`, and rebuilds the boot images.

Use the helper instead of hand-copying files so the Secure Boot/Limine detection
and refresh path stays consistent:

```sh
sudo ./scripts/install/plymouth-luks-theme.sh
```

If Limine is not installed, the helper falls back to `mkinitcpio -P`. If Secure
Boot, Limine verification, or Limine config enrollment appears to be enabled, it
prints the needed refresh plan before asking for confirmation.

## Recovery

If the prompt is visually wrong but input still works, type the LUKS password
blindly and press Enter. To restore the CachyOS Plymouth theme:

```sh
sudo plymouth-set-default-theme cachyos
sudo sed -i '/^DeviceScale=/d' /etc/plymouth/plymouthd.conf
sudo limine-mkinitcpio
command -v refresh-limine-secureboot-assets >/dev/null && \
  sudo refresh-limine-secureboot-assets --refresh-assets-only
```

If the machine is not using Limine, rebuild with `sudo mkinitcpio -P`.
