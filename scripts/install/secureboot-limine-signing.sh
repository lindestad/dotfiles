#!/usr/bin/env bash
set -euo pipefail

signer_path="/usr/local/bin/sign-secureboot-bootfiles"
hook_path="/etc/pacman.d/hooks/zzzz-sign-secureboot-bootfiles.hook"
ts="$(date +%Y%m%d-%H%M%S)"

die() {
  echo "!! $*" >&2
  exit 1
}

backup_file() {
  local path="$1"
  [[ -e "$path" ]] || return 0
  cp -a "$path" "${path}.bak.${ts}"
  echo "-> Backed up $path to ${path}.bak.${ts}"
}

write_root_file() {
  local path="$1"
  local mode="$2"
  local tmp
  tmp="$(mktemp)"
  cat >"$tmp"
  install -D -m "$mode" "$tmp" "$path"
  rm -f "$tmp"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "run with sudo: sudo $0"
fi

command -v sbctl >/dev/null 2>&1 || die "sbctl is required"
[[ -d /boot ]] || die "/boot does not exist"

if ! command -v limine-update >/dev/null 2>&1; then
  echo ">> limine-update was not found; installing the hook anyway for /boot signing" >&2
fi

backup_file "$signer_path"
write_root_file "$signer_path" 0755 <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

find /boot -type f \( -iname '*.efi' -o -name 'vmlinuz-*' \) -print0 |
  while IFS= read -r -d '' file; do
    sbctl sign -s "$file"
  done
EOF
echo "-> Wrote $signer_path"

backup_file "$hook_path"
write_root_file "$hook_path" 0644 <<'EOF'
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Target = usr/lib/modules/*/vmlinuz
Target = usr/lib/modules/*/pkgbase

[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = linux-cachyos
Target = linux-cachyos-lts
Target = limine
Target = limine-mkinitcpio-hook
Target = mkinitcpio

[Action]
Description = Signing Limine Secure Boot files...
When = PostTransaction
Exec = /usr/local/bin/sign-secureboot-bootfiles
EOF
echo "-> Wrote $hook_path"

echo "==> Signing current /boot EFI and kernel images"
"$signer_path"

echo
echo "Done. Verify before enabling Secure Boot:"
echo "  sudo sbctl verify"
