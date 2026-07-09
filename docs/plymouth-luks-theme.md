# Plymouth LUKS Theme

This setup uses the `hexagon_alt` animation assets from a pinned fork of
`adi1090x/plymouth-themes` for the graphical LUKS unlock prompt on CachyOS.

The installed theme is generated locally as `hexagon_alt_twostep`. It uses
Plymouth's stock `two-step` plugin for the LUKS prompt, so prompt centering,
multi-display layout, keyboard layout, and Caps Lock handling come from
Plymouth's maintained implementation instead of a custom script callback.

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
- writes two-step theme metadata around the hexagon animation assets;
- converts the upstream `progress-*.png` hexagon frames to `throbber-*.png`
  frames and removes the copied `progress-*.png` files from the generated
  two-step theme, so Plymouth shows the hexagon as the continuous waiting
  animation instead of a static progress overlay;
- copies Plymouth's stock prompt assets from the installed `spinner` theme:
  `entry.png`, `bullet.png`, `lock.png`, `capslock.png`, `keyboard.png`, and
  `keymap-render.png`;
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
theme uses `Noto Sans` and `Noto Sans Mono`, which have reliable coverage for
the stock prompt text and bullet dot. On CachyOS/Arch, keep `noto-fonts`
installed:

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
that display's own width and height.

The upstream `hexagon_alt` theme is a script theme with one global sprite
coordinate space. That is the source of the display-centering problems this
setup avoids by generating a `two-step` theme instead.

Plymouth's `two-step` plugin treats `throbber-*.png` as the continuous waiting
animation and `progress-*.png` as an optional progress-driven overlay. The
installer therefore maps the hexagon frames to `throbber-*.png` and removes the
`progress-*.png` copies from the generated theme.

The prompt dialog is placed below the hexagon with `DialogVerticalAlignment=.68`
while the hexagon itself is kept above center with `VerticalAlignment=.42`.

## Caps Lock

The stock `two-step` prompt shows Caps Lock by using Plymouth's internal
`ply-capslock-icon` helper, which polls renderer caps-lock state and draws
`capslock.png` near the prompt. Because this setup now uses `two-step`, the
Caps Lock warning comes from Plymouth itself.

## Manual Equivalent

```sh
tmp="$(mktemp -d)"
git clone --filter=blob:none --sparse --no-checkout \
  https://github.com/lindestad/plymouth-themes.git "$tmp/plymouth-themes"
git -C "$tmp/plymouth-themes" sparse-checkout set pack_2/hexagon_alt
git -C "$tmp/plymouth-themes" fetch --depth 1 origin \
  5d8817458d764bff4ff9daae94cf1bbaabf16ede
git -C "$tmp/plymouth-themes" checkout --detach \
  5d8817458d764bff4ff9daae94cf1bbaabf16ede

sudo rm -rf /usr/share/plymouth/themes/hexagon_alt_twostep
sudo install -d -m 0755 /usr/share/plymouth/themes/hexagon_alt_twostep
sudo cp -r "$tmp/plymouth-themes/pack_2/hexagon_alt/." \
  /usr/share/plymouth/themes/hexagon_alt_twostep/
sudo cp /usr/share/plymouth/themes/spinner/{entry,bullet,lock,capslock,keyboard,keymap-render}.png \
  /usr/share/plymouth/themes/hexagon_alt_twostep/
sudo find /usr/share/plymouth/themes/hexagon_alt_twostep \
  -maxdepth 1 -type f -name 'progress-*.png' -delete
i=1
find "$tmp/plymouth-themes/pack_2/hexagon_alt" \
  -maxdepth 1 -type f -name 'progress-*.png' -printf '%f\n' |
  sort -V |
  while IFS= read -r frame; do
    sudo install -m 0644 \
      "$tmp/plymouth-themes/pack_2/hexagon_alt/$frame" \
      "/usr/share/plymouth/themes/hexagon_alt_twostep/throbber-$(printf '%04d' "$i").png"
    i=$((i + 1))
  done

sudo tee /usr/share/plymouth/themes/hexagon_alt_twostep/hexagon_alt_twostep.plymouth >/dev/null <<'EOF'
[Plymouth Theme]
Name=hexagon_alt_twostep
Description=hexagon_alt animation with Plymouth two-step LUKS prompt
Comment=hexagon_alt assets from adi1090x/plymouth-themes
ModuleName=two-step

[two-step]
Font=Noto Sans 14
TitleFont=Noto Sans Light 30
MonospaceFont=Noto Sans Mono 18
ImageDir=/usr/share/plymouth/themes/hexagon_alt_twostep
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.68
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.382
HorizontalAlignment=.5
VerticalAlignment=.42
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.96
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
MessageBelowAnimation=true

[boot-up]
UseAnimation=true
UseEndAnimation=false

[shutdown]
UseAnimation=true
UseEndAnimation=false

[reboot]
UseAnimation=true
UseEndAnimation=false
EOF

sudo cp -a /etc/plymouth/plymouthd.conf \
  "/etc/plymouth/plymouthd.conf.bak.$(date +%Y%m%d-%H%M%S)"
sudo tee /etc/plymouth/plymouthd.conf >/dev/null <<'EOF'
[Daemon]
Theme=hexagon_alt_twostep
EOF

sudo limine-mkinitcpio
command -v limine-snapper-sync >/dev/null && sudo limine-snapper-sync

# If Secure Boot, Limine verification, or Limine config enrollment is active:
command -v refresh-limine-secureboot-assets >/dev/null && \
  sudo refresh-limine-secureboot-assets --refresh-assets-only

command -v limine-snapper-info >/dev/null && sudo limine-snapper-info
```

If Limine is not installed, use `sudo mkinitcpio -P` instead of
the Limine commands. If the Secure Boot refresh helper is missing on a machine
with Secure Boot or Limine verification enabled, refresh Limine hashes and
config enrollment manually before rebooting.

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
