# Plymouth LUKS Theme

This setup uses the `hexagon_alt` Plymouth theme from
`adi1090x/plymouth-themes` for the graphical LUKS unlock prompt on CachyOS.

The theme is intentionally simple at unlock time: it shows the hexagon
animation in the center and Plymouth's script password callback near the
bottom. It does not add an OS logo or extra branding.

## Install

Run from the repo root:

```sh
sudo ./scripts/install/plymouth-luks-theme.sh
```

The optional first argument sets Plymouth's integer `DeviceScale`:

```sh
sudo ./scripts/install/plymouth-luks-theme.sh 2
```

The helper:

- fetches only `pack_2/hexagon_alt` from `adi1090x/plymouth-themes`;
- installs it to `/usr/share/plymouth/themes/hexagon_alt`;
- patches the theme script to center the animation and password prompt
  consistently and to use password bullet dots instead of `*`;
- writes `/etc/plymouth/plymouthd.conf` with `Theme=hexagon_alt` and
  `DeviceScale=2`;
- rebuilds boot images with `limine-mkinitcpio` when available, otherwise
  falls back to `mkinitcpio -P`.

## Requirements

The mkinitcpio config must include the `plymouth` hook before `sd-encrypt`.
The kernel command line must include `splash`.

Plymouth script themes need a font in the initramfs for the password prompt.
On CachyOS/Arch, keep at least one of these installed:

```sh
pacman -Q cantarell-fonts ttf-dejavu
```

Fonts are not copied manually into `/boot`. The mkinitcpio Plymouth hook
resolves fonts with `fc-match` and packs them into the generated initramfs.

## Manual Equivalent

```sh
tmp="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/adi1090x/plymouth-themes.git "$tmp/plymouth-themes"
git -C "$tmp/plymouth-themes" sparse-checkout set pack_2/hexagon_alt

sudo rm -rf /usr/share/plymouth/themes/hexagon_alt
sudo install -d -m 0755 /usr/share/plymouth/themes/hexagon_alt
sudo cp -r "$tmp/plymouth-themes/pack_2/hexagon_alt/." \
  /usr/share/plymouth/themes/hexagon_alt/

sudo cp -a /etc/plymouth/plymouthd.conf \
  "/etc/plymouth/plymouthd.conf.bak.$(date +%Y%m%d-%H%M%S)"
sudo tee /etc/plymouth/plymouthd.conf >/dev/null <<'EOF'
[Daemon]
Theme=hexagon_alt
DeviceScale=2
EOF

sudo limine-mkinitcpio
```

If Limine is not installed, use `sudo mkinitcpio -P` instead of
`sudo limine-mkinitcpio`.

## Recovery

If the prompt is visually wrong but input still works, type the LUKS password
blindly and press Enter. To restore the CachyOS Plymouth theme:

```sh
sudo plymouth-set-default-theme cachyos
sudo sed -i '/^DeviceScale=/d' /etc/plymouth/plymouthd.conf
sudo limine-mkinitcpio
```

If the machine is not using Limine, rebuild with `sudo mkinitcpio -P`.
