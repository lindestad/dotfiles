#!/usr/bin/env bash
set -euo pipefail

unsafe_signer_path="/usr/local/bin/sign-secureboot-bootfiles"
unsafe_hook_path="/etc/pacman.d/hooks/zzzz-sign-secureboot-bootfiles.hook"
asset_refresher_path="/usr/local/bin/refresh-limine-secureboot-assets"
asset_hook_path="/etc/pacman.d/hooks/zzzz-refresh-limine-secureboot-assets.hook"
limine_default="/etc/default/limine"
ts="$(date +%Y%m%d-%H%M%S)"
rescue_dir="/root/limine-secureboot-rescue-${ts}"

die() {
  echo "!! $*" >&2
  command -v logger >/dev/null 2>&1 && logger -t limine-secureboot-assets -- "$*"
  exit 1
}

have() {
  command -v "$1" >/dev/null 2>&1
}

backup_move() {
  local path="$1"
  local label="$2"

  [[ -e "$path" ]] || return 0
  mkdir -p "$rescue_dir"
  mv "$path" "$rescue_dir/$(basename "$path").disabled"
  echo "-> Disabled $label: $path"
  echo "   Backup: $rescue_dir/$(basename "$path").disabled"
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

ensure_limine_option() {
  local key="$1"
  local value="$2"

  if [[ ! -e "$limine_default" ]]; then
    install -D -m 0644 /dev/null "$limine_default"
  fi
  if grep -qE "^${key}=" "$limine_default"; then
    sed -i "s/^${key}=.*/${key}=${value}/" "$limine_default"
  else
    printf '\n%s=%s\n' "$key" "$value" >>"$limine_default"
  fi
}

esp_path() {
  local configured=""

  if [[ -f "$limine_default" ]]; then
    configured="$(
      sed -nE 's/^[[:space:]]*ESP_PATH="?([^"#[:space:]]+)"?.*$/\1/p' "$limine_default" |
        tail -n 1
    )"
  fi

  printf '%s\n' "${configured:-/boot}"
}

remove_saved_kernel_signatures() {
  local saved_files=()
  local file

  while IFS= read -r file; do
    saved_files+=("$file")
  done < <(sbctl list-files | awk '/^\/boot\/[^/]+\/.*\/vmlinuz/ { print $1 }')

  if ((${#saved_files[@]} == 0)); then
    echo "-> No Limine kernel copies were saved in the sbctl database"
    return 0
  fi

  echo "==> Removing Limine kernel copies from the sbctl saved-file database"
  for file in "${saved_files[@]}"; do
    sbctl remove-file "$file"
  done
}

install_asset_refresher() {
  local source_path

  source_path="$(readlink -f "${BASH_SOURCE[0]}")"
  install -D -m 0755 "$source_path" "$asset_refresher_path"
  echo "-> Installed $asset_refresher_path"
}

install_asset_hook() {
  write_root_file "$asset_hook_path" 0644 <<'EOF'
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
Target = limine-snapper-sync
Target = mkinitcpio
Target = cachyos-wallpapers

[Action]
Description = Refreshing Limine Secure Boot asset hashes...
When = PostTransaction
Exec = /usr/local/bin/refresh-limine-secureboot-assets --refresh-assets-only
EOF
  echo "-> Installed $asset_hook_path"
}

verify_limine_hashes() {
  local esp="$1"
  local conf="${esp}/limine.conf"
  local count=0
  local failed=0
  local spec rel expected file actual

  have b2sum || die "b2sum is required"
  [[ -f "$conf" ]] || die "$conf does not exist"

  while IFS= read -r spec; do
    rel="${spec%%#*}"
    expected="${spec##*#}"
    file="${esp}${rel}"
    count=$((count + 1))

    if [[ ! -f "$file" ]]; then
      echo "!! Missing Limine boot file: $rel" >&2
      failed=1
      continue
    fi

    actual="$(b2sum "$file" | awk '{ print $1 }')"
    if [[ "$actual" != "$expected" ]]; then
      echo "!! Limine hash mismatch: $rel" >&2
      failed=1
    fi
  done < <(
    awk 'match($0,/boot\(\):\/[^[:space:]]+#[0-9a-f]+/) {
      spec = substr($0, RSTART, RLENGTH)
      sub(/^boot\(\):/, "", spec)
      print spec
    }' "$conf"
  )

  if ((count == 0)); then
    die "no Limine verification hashes were found in $conf"
  fi

  if ((failed != 0)); then
    die "Limine verification hashes do not match"
  fi

  echo "-> Verified $count Limine file hashes"
}

hash_limine_wallpapers() {
  local esp="$1"
  local conf="${esp}/limine.conf"
  local tmp
  local changed=0
  local missing=0
  local line prefix rel suffix rest file hash

  have b2sum || die "b2sum is required"
  [[ -f "$conf" ]] || die "$conf does not exist"

  tmp="$(mktemp)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([[:space:]]*wallpaper:[[:space:]]*)boot\(\):([^[:space:]#]+)(#[^[:space:]]+)?(.*)$ ]]; then
      prefix="${BASH_REMATCH[1]}"
      rel="${BASH_REMATCH[2]}"
      suffix="${BASH_REMATCH[3]}"
      rest="${BASH_REMATCH[4]}"
      file="${esp}${rel}"

      if [[ -f "$file" ]]; then
        hash="$(b2sum "$file" | awk '{ print $1 }')"
        if [[ "$suffix" != "#${hash}" ]]; then
          line="${prefix}boot():${rel}#${hash}${rest}"
          changed=1
        fi
      else
        echo "!! Limine wallpaper file not found: boot():${rel}" >&2
        command -v logger >/dev/null 2>&1 &&
          logger -t limine-secureboot-assets -- "Limine wallpaper file not found: boot():${rel}"
        missing=1
      fi
    fi

    printf '%s\n' "$line" >>"$tmp"
  done <"$conf"

  if ((missing != 0)); then
    rm -f "$tmp"
    die "one or more Limine wallpaper files were missing; asset hash refresh aborted"
  fi

  if ((changed != 0)); then
    install -m 0644 "$tmp" "$conf"
    echo "-> Added or refreshed Limine wallpaper hashes"
  else
    echo "-> Limine wallpaper hashes are current"
  fi
  rm -f "$tmp"
}

refresh_limine_fallback() {
  local esp="$1"
  local primary="${esp}/EFI/limine/limine_x64.efi"
  local fallback="${esp}/EFI/BOOT/BOOTX64.EFI"

  [[ -f "$primary" ]] || die "$primary does not exist"
  grep -a -qi 'limine' "$primary" || die "$primary does not look like a Limine EFI binary"

  if [[ ! -f "$fallback" ]]; then
    echo "-> No Limine fallback EFI found; skipping"
    return 0
  fi

  if ! grep -a -qi 'limine' "$fallback"; then
    echo "-> Existing fallback EFI is not Limine; leaving unchanged"
    return 0
  fi

  if cmp -s "$primary" "$fallback"; then
    echo "-> Limine fallback EFI is current"
    return 0
  fi

  cp -f "$primary" "$fallback"
  sync -f "$fallback" 2>/dev/null || sync
  echo "-> Refreshed Limine fallback EFI"
}

refresh_assets() {
  local esp

  have limine-enroll-config || die "limine-enroll-config is required"

  esp="$(esp_path)"

  echo "==> Hashing Limine theme assets"
  hash_limine_wallpapers "$esp"

  echo "==> Enrolling Limine config checksum"
  limine-enroll-config

  refresh_limine_fallback "$esp"
  verify_limine_hashes "$esp"
}

refresh_assets_only=0
case "${1:-}" in
--refresh-assets-only)
  refresh_assets_only=1
  shift
  ;;
--help | -h)
  cat <<EOF
Usage:
  sudo $0
  sudo $0 --refresh-assets-only
EOF
  exit 0
  ;;
esac

if (($# != 0)); then
  die "unknown arguments: $*"
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "run with sudo: sudo $0"
fi

if ((refresh_assets_only != 0)); then
  refresh_assets
  exit 0
fi

have sbctl || die "sbctl is required"
have limine-update || die "limine-update is required"
have limine-enroll-config || die "limine-enroll-config is required"

echo "==> Disabling unsafe legacy signing hook, if present"
backup_move "$unsafe_hook_path" "legacy pacman hook"
backup_move "$unsafe_signer_path" "legacy signing helper"

echo "==> Enabling Limine config enrollment and file verification"
ensure_limine_option "ENABLE_ENROLL_LIMINE_CONFIG" "yes"
ensure_limine_option "ENABLE_VERIFICATION" "yes"

echo "==> Installing safe Limine Secure Boot asset refresh hook"
install_asset_refresher
install_asset_hook

remove_saved_kernel_signatures

echo "==> Regenerating Limine entries"
limine-update

if have limine-snapper-sync; then
  echo "==> Regenerating Limine snapshot entries"
  limine-snapper-sync
fi

refresh_assets

if have limine-snapper-info; then
  echo "==> Snapshot file check"
  limine-snapper-info
fi

echo
echo "Done."
echo "Do not sign Limine-managed vmlinuz files under /boot/<machine-id>/."
echo "sbctl verify may still report those files as unsigned; Limine validates them with hashes in limine.conf."
