# Secure Boot With Limine

Limine v12 can protect boot files with hashes in `limine.conf`. On CachyOS,
the safe setup is:

- enable Limine config enrollment;
- enable Limine file verification;
- let Limine generate hashes for its kernel and initramfs copies;
- sign the Limine EFI binary, not the Limine-managed kernel copies.

Do not run a blanket `sbctl sign` over `/boot`. In particular, do not sign
files below `/boot/<machine-id>/.../vmlinuz-*` or
`/boot/<machine-id>/limine_history/vmlinuz-*` after `limine.conf` has been
generated. Signing those files changes their bytes, so the hashes embedded in
`limine.conf` no longer match and Limine refuses to boot the entries.

The failure mode is documented in
[limine-secureboot-hash-issue.md](./limine-secureboot-hash-issue.md).

## Repair Or Refresh

Run from the repo root:

```sh
sudo ./scripts/install/secureboot-limine-signing.sh
```

The helper:

- disables the old unsafe signing hook if it exists;
- removes Limine-managed `vmlinuz` files from `sbctl`'s saved-file database;
- sets `ENABLE_ENROLL_LIMINE_CONFIG=yes`;
- sets `ENABLE_VERIFICATION=yes`;
- runs `limine-update`;
- runs `limine-snapper-sync` when available;
- verifies every `boot():/...#hash` entry in `limine.conf`.

## Expected Verification Output

`sbctl verify` may still report Limine-managed kernel copies as unsigned:

```text
/boot/<machine-id>/linux-cachyos/vmlinuz-linux-cachyos is not signed
```

That is expected for this setup. Limine validates those files using the hashes
in `limine.conf`.

The important checks are:

```sh
sudo limine-snapper-info
```

which should report:

```text
Corrupted files   : 0
```

and the helper's own hash check:

```text
Verified <n> Limine file hashes
```

## Manual Update Order

After changing Limine config or kernel/initramfs inputs:

```sh
sudo limine-update
sudo limine-snapper-sync
sudo limine-snapper-info
```

If Secure Boot keys need to be enrolled, include Microsoft keys so Windows
continues to boot:

```sh
sudo sbctl enroll-keys --microsoft
```
