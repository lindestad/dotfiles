# SDDM LUKS Autologin

This setup uses `pam_systemd_loadkey` to reuse the LUKS passphrase entered
during early boot for SDDM autologin. The display manager logs in without a
second password prompt, and GNOME Keyring or KWallet can unlock from the same
passphrase.

This only works when the boot path uses systemd-based disk unlock. On
CachyOS/Arch that means:

- the kernel command line contains `rd.luks.uuid=...` or equivalent
  `rd.luks.*` parameters;
- `/etc/mkinitcpio.conf` uses the `systemd` and `sd-encrypt` hooks;
- the keyring or wallet password matches the LUKS passphrase.

## Install

Run from the repo root:

```sh
sudo ./scripts/install/sddm-luks-autologin.sh dl niri.desktop
```

The helper:

- adds `pam_systemd_loadkey.so` to `/etc/pam.d/sddm-autologin` before the
  GNOME Keyring or KWallet auth line;
- writes `/etc/systemd/system/sddm.service.d/keyringmode.conf` with
  `KeyringMode=inherit`;
- writes `/etc/sddm.conf.d/10-autologin.conf` for the requested user and
  session;
- backs up any changed root-owned files with a timestamp suffix.

Reboot to test. Do not restart SDDM from inside the active graphical session.

## Recovery

To disable SDDM autologin:

```sh
sudo rm -f /etc/sddm.conf.d/10-autologin.conf
sudo systemctl daemon-reload
```

To fully remove the cached-passphrase integration, also restore the timestamped
backup of `/etc/pam.d/sddm-autologin` and remove:

```sh
sudo rm -f /etc/systemd/system/sddm.service.d/keyringmode.conf
sudo systemctl daemon-reload
```
