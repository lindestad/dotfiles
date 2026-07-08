# Limine Secure Boot Hash Issue

## What Happened

A custom pacman hook signed every EFI binary and every `vmlinuz-*` file below
`/boot` after kernel and Limine updates.

That was wrong for Limine v12 with file verification enabled. Limine writes
BLAKE2 hashes into `limine.conf` for the kernel, initramfs, and snapshot boot
files it loads. Signing a `vmlinuz` file changes the file contents after those
hashes are written, so Limine detects the file as modified and rejects the boot
entry.

Snapshots can fail at the same time because snapshot entries reuse files stored
on the ESP under `limine_history`. The ESP is outside the Btrfs root snapshots,
so rolling back the root filesystem does not roll back those boot files.

## Symptoms

- Secure Boot or Limine reports a hash, signature, or verification mismatch.
- Current kernel entries and older snapshot entries all fail.
- `limine-snapper-info` reports corrupted snapshot files.
- `sbctl verify` may show Limine-managed `vmlinuz` files as unsigned after the
  fix. That is not the failure; for this setup Limine hash verification is what
  protects those files.

## Correct Model

- `sbctl` signs EFI executables such as Limine's EFI binary.
- Limine validates its managed kernel/initramfs files with hashes in
  `limine.conf`.
- The Limine-managed files under `/boot/<machine-id>/` and
  `/boot/<machine-id>/limine_history/` should not be modified after
  `limine.conf` is generated.

## Recovery Checklist

From a live USB or a working chroot:

```sh
mv /etc/pacman.d/hooks/zzzz-sign-secureboot-bootfiles.hook \
  /root/zzzz-sign-secureboot-bootfiles.hook.disabled 2>/dev/null || true

mv /usr/local/bin/sign-secureboot-bootfiles \
  /root/sign-secureboot-bootfiles.disabled 2>/dev/null || true

sbctl list-files | awk '/^\/boot\/[^/]+\/.*\/vmlinuz/ { print $1 }' |
  while read -r file; do
    sbctl remove-file "$file"
  done

printf '\nENABLE_ENROLL_LIMINE_CONFIG=yes\nENABLE_VERIFICATION=yes\n' >> /etc/default/limine

limine-update
limine-snapper-sync
limine-snapper-info
```

If `limine-snapper-info` still reports corrupted files, compare the corrupted
history file with the regenerated current kernel copy. When the expected hashes
match the current copy, back up the corrupted history file and replace it with
the current copy.

## Prevention

Do not reintroduce a pacman hook that signs all `vmlinuz-*` files under
`/boot`. Use `scripts/install/secureboot-limine-signing.sh` only as a cleanup
and refresh helper.
