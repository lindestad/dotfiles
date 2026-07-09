#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/lindestad/plymouth-themes.git"
repo_ref="5d8817458d764bff4ff9daae94cf1bbaabf16ede"
repo_theme_path="pack_2/hexagon_alt"
theme_name="hexagon_alt_twostep"
theme_dst="/usr/share/plymouth/themes/$theme_name"
scale=""
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
DialogVerticalAlignment=.382
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.382
HorizontalAlignment=.5
VerticalAlignment=.5
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.96
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false

[shutdown]
UseEndAnimation=false

[reboot]
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

usage() {
  cat <<EOF
Usage: $(basename "$0") [scale]

Installs a two-step Plymouth theme using the hexagon_alt animation, optionally
sets Plymouth DeviceScale, and rebuilds the Limine or mkinitcpio boot image.

Arguments:
  scale   Optional positive integer Plymouth DeviceScale value. Default: auto
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    scale="$1"
    ;;
esac

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "run with sudo: sudo $0 [scale]"
fi

[[ -z "$scale" || "$scale" =~ ^[1-9][0-9]*$ ]] || die "scale must be a positive integer"
command -v git >/dev/null 2>&1 || die "git is required"
[[ -e /usr/lib/plymouth/two-step.so ]] || die "Plymouth two-step plugin is not installed"

if ! command -v limine-mkinitcpio >/dev/null 2>&1; then
  command -v mkinitcpio >/dev/null 2>&1 || die "mkinitcpio is required"
fi

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

if command -v limine-mkinitcpio >/dev/null 2>&1; then
  echo "==> Rebuilding Limine initramfs entries"
  limine-mkinitcpio
else
  echo "==> Rebuilding initramfs"
  mkinitcpio -P
fi

echo
echo "Done. Reboot to test the LUKS prompt."
