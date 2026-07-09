#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/lindestad/plymouth-themes.git"
repo_ref="5d8817458d764bff4ff9daae94cf1bbaabf16ede"
repo_theme_path="pack_2/hexagon_alt"
theme_name="hexagon_alt_twostep"
theme_dst="/usr/share/plymouth/themes/$theme_name"
scale=""
assume_yes=0
boot_backend=""
secure_boot_state="not detected"
limine_verification="unknown"
limine_config_enrollment="unknown"
plymouth_hook_state="unknown"
ts="$(date +%Y%m%d-%H%M%S)"
tmp_dir=""

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

cleanup() {
  [[ -z "$tmp_dir" ]] || rm -rf "$tmp_dir"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

config_value_from_file() {
  local file="$1"
  local key="$2"

  awk -v key="$key" '
    $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub(/^[^=]*=[[:space:]]*/, "")
      sub(/[[:space:]]*#.*/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      gsub(/^"|"$/, "")
      value = $0
    }
    END {
      if (value != "") print value
    }
  ' "$file"
}

limine_config_value() {
  local key="$1"
  local file value next

  for file in /etc/limine-entry-tool.conf /etc/default/limine; do
    [[ -f "$file" ]] || continue
    next="$(config_value_from_file "$file" "$key" || true)"
    [[ -n "$next" ]] && value="$next"
  done

  printf '%s\n' "${value:-}"
}

limine_default_value() {
  local key="$1"

  [[ -f /etc/default/limine ]] || return 0
  config_value_from_file /etc/default/limine "$key"
}

value_is_enabled() {
  case "${1,,}" in
    1|yes|true|on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

secure_boot_summary() {
  local sb_var="/sys/firmware/efi/efivars/SecureBoot-8be4df61-93ca-11d2-aa0d-00e098032b8c"
  local sb_byte

  if [[ ! -r "$sb_var" ]]; then
    printf 'not detected\n'
    return 0
  fi

  sb_byte="$(od -An -t u1 -j4 -N1 "$sb_var" 2>/dev/null | tr -d ' ')"
  if [[ "$sb_byte" == "1" ]]; then
    printf 'enabled\n'
  else
    printf 'disabled\n'
  fi
}

mkinitcpio_has_plymouth_hook() {
  local files=()

  [[ -f /etc/mkinitcpio.conf ]] && files+=(/etc/mkinitcpio.conf)

  shopt -s nullglob
  files+=(/etc/mkinitcpio.conf.d/*.conf)
  shopt -u nullglob

  ((${#files[@]} > 0)) || return 1

  awk '
    /^[[:space:]]*HOOKS[[:space:]]*=/ {
      line = $0
      sub(/[[:space:]]*#.*/, "", line)
      if (line ~ /(^|[^[:alnum:]_-])plymouth([^[:alnum:]_-]|$)/) found = 1
    }
    END { exit found ? 0 : 1 }
  ' "${files[@]}" 2>/dev/null
}

detect_boot_environment() {
  if have limine-mkinitcpio; then
    boot_backend="limine"
  elif have mkinitcpio; then
    boot_backend="mkinitcpio"
  else
    die "limine-mkinitcpio or mkinitcpio is required"
  fi

  secure_boot_state="$(secure_boot_summary)"
  limine_verification="$(limine_config_value ENABLE_VERIFICATION)"
  limine_config_enrollment="$(limine_default_value ENABLE_ENROLL_LIMINE_CONFIG)"

  if mkinitcpio_has_plymouth_hook; then
    plymouth_hook_state="present"
  else
    plymouth_hook_state="not found"
  fi
}

limine_secure_refresh_risk() {
  [[ "$boot_backend" == "limine" ]] || return 1

  [[ "$secure_boot_state" == "enabled" ]] && return 0
  value_is_enabled "$limine_verification" && return 0
  value_is_enabled "$limine_config_enrollment" && return 0

  return 1
}

print_install_plan() {
  echo "==> Planned Plymouth theme install"
  echo "-> Source assets: $repo_url"
  echo "-> Pinned commit: $repo_ref"
  echo "-> Target theme: $theme_dst"
  echo "-> Plymouth theme: $theme_name"
  echo "-> Animation: hexagon frames converted to two-step throbber frames"
  if [[ -n "$scale" ]]; then
    echo "-> Plymouth DeviceScale: $scale"
  else
    echo "-> Plymouth DeviceScale: auto"
  fi
  echo "-> mkinitcpio Plymouth hook: $plymouth_hook_state"
  echo "-> Secure Boot: $secure_boot_state"

  if [[ "$boot_backend" == "limine" ]]; then
    echo "-> Limine verification: ${limine_verification:-not set}"
    echo "-> Limine config enrollment: ${limine_config_enrollment:-not set}"
    echo "-> Boot image rebuild: limine-mkinitcpio"
    if have limine-snapper-sync; then
      echo "-> Snapshot entries: limine-snapper-sync"
    fi
    if limine_secure_refresh_risk; then
      if have refresh-limine-secureboot-assets; then
        echo "-> Limine Secure Boot refresh: refresh-limine-secureboot-assets --refresh-assets-only"
        echo "   This refreshes Limine file hashes, enrolls the Limine config checksum,"
        echo "   refreshes the Limine fallback EFI when applicable, signs the Limine EFI"
        echo "   through limine-enroll-config/sbctl when configured, and verifies hashes."
      else
        echo "!! Limine Secure Boot refresh helper was not found."
        echo "   This machine appears to use Secure Boot and/or Limine verification."
        echo "   Rebuilding initramfs can require refreshed Limine hashes and config"
        echo "   enrollment. Install scripts/install/secureboot-limine-signing.sh first"
        echo "   for the managed safe path, or refresh hashes/enrollment manually."
      fi
    else
      echo "-> Limine Secure Boot refresh: skipped; Secure Boot/Limine verification not detected"
    fi
    if have limine-snapper-info; then
      echo "-> Snapshot verification: limine-snapper-info"
    fi
  else
    echo "-> Boot image rebuild: mkinitcpio -P"
    if [[ "$secure_boot_state" == "enabled" ]]; then
      echo "!! Secure Boot is enabled, but Limine was not detected."
      echo "   This installer cannot know how this machine signs or verifies boot"
      echo "   images. Proceed only if this machine's boot chain handles regenerated"
      echo "   initramfs files outside this script."
    fi
  fi

  if [[ "$plymouth_hook_state" != "present" ]]; then
    echo "!! The mkinitcpio HOOKS line does not appear to include plymouth."
    echo "   The theme can be installed, but the graphical LUKS prompt may not show"
    echo "   until the plymouth hook is added before sd-encrypt."
  fi
}

confirm_install() {
  local answer

  if ((assume_yes != 0)); then
    return 0
  fi

  if [[ ! -t 0 ]]; then
    die "confirmation requires a TTY; rerun with --yes to proceed non-interactively"
  fi

  echo
  read -r -p "Proceed with installing the theme and rebuilding boot images? [Y/n] " answer
  case "$answer" in
    ""|[Yy]|[Yy][Ee][Ss])
      return 0
      ;;
    *)
      echo "Aborted."
      exit 0
      ;;
  esac
}

write_theme_metadata() {
  local metadata_path="$theme_dst/$theme_name.plymouth"

  cat >"$metadata_path" <<EOF
[Plymouth Theme]
Name=$theme_name
Description=hexagon_alt animation with Plymouth two-step LUKS prompt
Comment=hexagon_alt assets from adi1090x/plymouth-themes, installed from $repo_url at $repo_ref
ModuleName=two-step

[two-step]
Font=Noto Sans 14
TitleFont=Noto Sans Light 30
MonospaceFont=Noto Sans Mono 18
ImageDir=$theme_dst
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

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing Updates...
SubTitle=Do not turn off your computer

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading System...
SubTitle=Do not turn off your computer

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading Firmware...
SubTitle=Do not turn off your computer

[system-reset]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Resetting System...
SubTitle=Do not turn off your computer
EOF
}

copy_prompt_assets() {
  local src_dir="/usr/share/plymouth/themes/spinner"
  local asset

  for asset in entry.png bullet.png lock.png capslock.png keyboard.png keymap-render.png; do
    [[ -f "$src_dir/$asset" ]] || die "required two-step prompt asset not found: $src_dir/$asset"
    install -m 0644 "$src_dir/$asset" "$theme_dst/$asset"
  done
}

prepare_two_step_animation() {
  local frames=()
  local frame
  local index=1
  local target

  mapfile -t frames < <(
    find "$theme_src" -maxdepth 1 -type f -name 'progress-*.png' -printf '%f\n' |
      sort -V
  )
  ((${#frames[@]} > 0)) || die "theme animation frames not found: $theme_src/progress-*.png"

  find "$theme_dst" -maxdepth 1 -type f -name 'progress-*.png' -delete
  find "$theme_dst" -maxdepth 1 -type f -name 'throbber-*.png' -delete

  for frame in "${frames[@]}"; do
    target="$(printf 'throbber-%04d.png' "$index")"
    install -m 0644 "$theme_src/$frame" "$theme_dst/$target"
    index=$((index + 1))
  done

  echo "-> Prepared $((index - 1)) hexagon throbber frames"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [scale]
       $(basename "$0") [--yes] [scale]

Installs a two-step Plymouth theme using the hexagon_alt animation, optionally
sets Plymouth DeviceScale, and rebuilds the Limine or mkinitcpio boot image.

Arguments:
  scale   Optional positive integer Plymouth DeviceScale value. Default: auto

Options:
  -y, --yes   Do not prompt before installing and rebuilding boot images
EOF
}

while (($# > 0)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -y|--yes)
      assume_yes=1
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      [[ -z "$scale" ]] || die "scale was provided more than once"
      scale="$1"
      ;;
  esac
  shift
done

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "run with sudo: sudo $0 [--yes] [scale]"
fi

[[ -z "$scale" || "$scale" =~ ^[1-9][0-9]*$ ]] || die "scale must be a positive integer"
have git || die "git is required"
[[ -e /usr/lib/plymouth/two-step.so ]] || die "Plymouth two-step plugin is not installed"

detect_boot_environment
print_install_plan
confirm_install

trap cleanup EXIT

echo "==> Fetching Plymouth theme assets: $repo_theme_path"
tmp_dir="$(mktemp -d)"
git clone --filter=blob:none --sparse --no-checkout "$repo_url" "$tmp_dir/plymouth-themes"
git -C "$tmp_dir/plymouth-themes" sparse-checkout set "$repo_theme_path"
git -C "$tmp_dir/plymouth-themes" fetch --depth 1 origin "$repo_ref"
git -C "$tmp_dir/plymouth-themes" checkout --detach "$repo_ref"
theme_src="$tmp_dir/plymouth-themes/$repo_theme_path"
[[ -f "$theme_src/hexagon_alt.plymouth" ]] || die "theme metadata not found: $theme_src/hexagon_alt.plymouth"
[[ -f "$theme_src/progress-0.png" ]] || die "theme animation frames not found: $theme_src/progress-0.png"

echo "==> Installing Plymouth theme: $theme_name"
if [[ -e "$theme_dst" ]]; then
  backup_file "$theme_dst"
  rm -rf "$theme_dst"
fi
install -d -m 0755 "$theme_dst"
cp -a "$theme_src/." "$theme_dst/"
copy_prompt_assets
prepare_two_step_animation
write_theme_metadata

echo "==> Setting Plymouth theme: $theme_name"
backup_file /etc/plymouth/plymouthd.conf
install -d -m 0755 /etc/plymouth
if [[ -n "$scale" ]]; then
  cat >/etc/plymouth/plymouthd.conf <<EOF
[Daemon]
Theme=$theme_name
DeviceScale=$scale
EOF
else
  cat >/etc/plymouth/plymouthd.conf <<EOF
[Daemon]
Theme=$theme_name
EOF
fi

if [[ "$boot_backend" == "limine" ]]; then
  echo "==> Rebuilding Limine initramfs entries"
  limine-mkinitcpio

  if have limine-snapper-sync; then
    echo "==> Regenerating Limine snapshot entries"
    limine-snapper-sync
  fi

  if limine_secure_refresh_risk; then
    if have refresh-limine-secureboot-assets; then
      echo "==> Refreshing Limine Secure Boot hashes and enrollment"
      refresh-limine-secureboot-assets --refresh-assets-only
    else
      echo "!! Skipped Limine Secure Boot hash/enrollment refresh; helper not found." >&2
      echo "!! Run scripts/install/secureboot-limine-signing.sh or refresh Limine hashes manually before rebooting." >&2
    fi
  else
    echo "==> Skipping Limine Secure Boot hash/enrollment refresh; not detected as needed"
  fi

  if have limine-snapper-info; then
    echo "==> Checking Limine snapshot files"
    limine-snapper-info
  fi
else
  echo "==> Rebuilding initramfs"
  mkinitcpio -P
fi

echo
echo "Done. Reboot to test the LUKS prompt."
