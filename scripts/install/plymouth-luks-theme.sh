#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/adi1090x/plymouth-themes.git"
repo_theme_path="pack_2/hexagon_alt"
theme_name="hexagon_alt"
theme_dst="/usr/share/plymouth/themes/$theme_name"
scale="2"
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

usage() {
  cat <<EOF
Usage: $(basename "$0") [scale]

Installs the adi1090x hexagon_alt Plymouth theme, sets Plymouth DeviceScale,
and rebuilds the Limine or mkinitcpio boot image.

Arguments:
  scale   Positive integer Plymouth DeviceScale value. Default: 2
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

[[ "$scale" =~ ^[1-9][0-9]*$ ]] || die "scale must be a positive integer"
command -v git >/dev/null 2>&1 || die "git is required"
[[ -e /usr/lib/plymouth/script.so ]] || die "Plymouth script plugin is not installed"

if ! command -v limine-mkinitcpio >/dev/null 2>&1; then
  command -v mkinitcpio >/dev/null 2>&1 || die "mkinitcpio is required"
fi

trap cleanup EXIT

echo "==> Fetching Plymouth theme: $theme_name"
tmp_dir="$(mktemp -d)"
git clone --depth 1 --filter=blob:none --sparse "$repo_url" "$tmp_dir/plymouth-themes"
git -C "$tmp_dir/plymouth-themes" sparse-checkout set "$repo_theme_path"
theme_src="$tmp_dir/plymouth-themes/$repo_theme_path"
[[ -f "$theme_src/$theme_name.plymouth" ]] || die "theme metadata not found: $theme_src/$theme_name.plymouth"
[[ -f "$theme_src/$theme_name.script" ]] || die "theme script not found: $theme_src/$theme_name.script"

echo "==> Installing Plymouth theme: $theme_name"
if [[ -e "$theme_dst" ]]; then
  backup_file "$theme_dst"
  rm -rf "$theme_dst"
fi
install -d -m 0755 "$theme_dst"
cp -a "$theme_src/." "$theme_dst/"

echo "==> Setting Plymouth scale: $scale"
backup_file /etc/plymouth/plymouthd.conf
install -d -m 0755 /etc/plymouth
cat >/etc/plymouth/plymouthd.conf <<EOF
[Daemon]
Theme=$theme_name
DeviceScale=$scale
EOF

if command -v limine-mkinitcpio >/dev/null 2>&1; then
  echo "==> Rebuilding Limine initramfs entries"
  limine-mkinitcpio
else
  echo "==> Rebuilding initramfs"
  mkinitcpio -P
fi

echo
echo "Done. Reboot to test the LUKS prompt."
