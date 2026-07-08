#!/usr/bin/env bash
set -euo pipefail

unsafe_signer_path="/usr/local/bin/sign-secureboot-bootfiles"
unsafe_hook_path="/etc/pacman.d/hooks/zzzz-sign-secureboot-bootfiles.hook"
limine_default="/etc/default/limine"
ts="$(date +%Y%m%d-%H%M%S)"
rescue_dir="/root/limine-secureboot-rescue-${ts}"

die() {
  echo "!! $*" >&2
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
  local line prefix rel suffix rest file hash

  have b2sum || die "b2sum is required"
  [[ -f "$conf" ]] || die "$conf does not exist"

  tmp="$(mktemp)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^([[:space:]]*wallpaper:[[:space:]]*)boot\(\):([^[:space:]#]+)(#[[:xdigit:]]+)?(.*)$ ]]; then
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
        echo ">> Wallpaper file not found, leaving unchanged: boot():${rel}" >&2
      fi
    fi

    printf '%s\n' "$line" >>"$tmp"
  done <"$conf"

  if ((changed != 0)); then
    install -m 0644 "$tmp" "$conf"
    echo "-> Added or refreshed Limine wallpaper hashes"
  else
    echo "-> Limine wallpaper hashes are current"
  fi
  rm -f "$tmp"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "run with sudo: sudo $0"
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

remove_saved_kernel_signatures

echo "==> Regenerating Limine entries"
limine-update

if have limine-snapper-sync; then
  echo "==> Regenerating Limine snapshot entries"
  limine-snapper-sync
fi

esp="$(esp_path)"

echo "==> Hashing Limine theme assets"
hash_limine_wallpapers "$esp"

echo "==> Enrolling Limine config checksum"
limine-enroll-config

verify_limine_hashes "$esp"

if have limine-snapper-info; then
  echo "==> Snapshot file check"
  limine-snapper-info
fi

echo
echo "Done."
echo "Do not sign Limine-managed vmlinuz files under /boot/<machine-id>/."
echo "sbctl verify may still report those files as unsigned; Limine validates them with hashes in limine.conf."
