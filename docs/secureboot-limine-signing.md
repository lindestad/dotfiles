# Secure Boot Limine Signing

CachyOS signs the top-level kernels through the normal `sbctl` hook, but
`limine-update` also creates Limine-managed kernel copies below `/boot`. Those
copies can be regenerated after the normal `zz-sbctl.hook` has already run.
Secure Boot should not be enabled while `sbctl verify` reports unsigned Limine
boot targets.

This helper installs a late pacman hook that signs every EFI binary and
`vmlinuz-*` file below `/boot` after kernel, mkinitcpio, or Limine package
updates.

## Install

Run from the repo root:

```sh
sudo ./scripts/install/secureboot-limine-signing.sh
```

The installer writes:

- `/usr/local/bin/sign-secureboot-bootfiles`
- `/etc/pacman.d/hooks/zzzz-sign-secureboot-bootfiles.hook`

It also signs the current `/boot` files once.

## Verify

After installing, check:

```sh
sudo sbctl verify
```

All listed EFI and kernel images should be signed before Secure Boot is enabled
in firmware.

## Manual Limine Updates

Pacman hooks only run during pacman transactions. If `limine-update` is run
manually, sign again afterwards:

```sh
sudo limine-update
sudo /usr/local/bin/sign-secureboot-bootfiles
sudo sbctl verify
```

## Notes

For ASUS and Gigabyte boards, enroll keys with Microsoft support but without
firmware builtin keys:

```sh
sudo sbctl enroll-keys --microsoft
```

Avoid `--firmware-builtin` on those boards because it can recreate duplicate
firmware key entries.
