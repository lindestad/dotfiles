#!/usr/bin/env bash
set -euo pipefail

target_user="${1:-${SUDO_USER:-}}"
target_session="${2:-niri.desktop}"
ts="$(date +%Y%m%d-%H%M%S)"

die() {
  echo "!! $*" >&2
  exit 1
}

warn() {
  echo ">> $*" >&2
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
  install -m "$mode" "$tmp" "$path"
  rm -f "$tmp"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  die "run with sudo: sudo $0 [user] [session.desktop]"
fi

[[ -n "$target_user" ]] || die "could not infer target user; pass it explicitly"
id "$target_user" >/dev/null 2>&1 || die "user does not exist: $target_user"

if [[ ! -f "/usr/share/wayland-sessions/$target_session" && ! -f "/usr/share/xsessions/$target_session" ]]; then
  die "session not found: $target_session"
fi

[[ -e /usr/lib/security/pam_systemd_loadkey.so ]] || die "pam_systemd_loadkey.so is not installed"

if ! grep -Eq '(^|[[:space:]])sd-encrypt([[:space:]]|$)' /etc/mkinitcpio.conf 2>/dev/null; then
  warn "/etc/mkinitcpio.conf does not appear to use sd-encrypt; cached LUKS passphrase reuse may not work"
fi

if ! grep -Eq '(^|[[:space:]])rd\.luks\.uuid=' /proc/cmdline 2>/dev/null; then
  warn "current kernel command line does not contain rd.luks.uuid=; cached LUKS passphrase reuse may not work"
fi

pam_file="/etc/pam.d/sddm-autologin"
if [[ ! -f "$pam_file" ]]; then
  if [[ -f /usr/lib/pam.d/sddm-autologin ]]; then
    install -m 0644 /usr/lib/pam.d/sddm-autologin "$pam_file"
    echo "-> Created $pam_file from /usr/lib/pam.d/sddm-autologin"
  else
    die "could not find sddm-autologin PAM config"
  fi
fi

if grep -q 'pam_systemd_loadkey\.so' "$pam_file"; then
  echo "-> $pam_file already loads pam_systemd_loadkey.so"
else
  backup_file "$pam_file"
  tmp="$(mktemp)"
  if ! awk '
    !inserted && $0 ~ /^-auth[[:space:]]+optional[[:space:]]+pam_(gnome_keyring|kwallet5)\.so/ {
      print "-auth       optional    pam_systemd_loadkey.so"
      inserted = 1
    }
    { print }
    END {
      if (!inserted) {
        exit 42
      }
    }
  ' "$pam_file" >"$tmp"; then
    rm -f "$tmp"
    die "could not find a keyring auth line in $pam_file to insert before"
  fi
  install -m 0644 "$tmp" "$pam_file"
  rm -f "$tmp"
  echo "-> Added pam_systemd_loadkey.so to $pam_file"
fi

install -d -m 0755 /etc/systemd/system/sddm.service.d
keyring_dropin="/etc/systemd/system/sddm.service.d/keyringmode.conf"
backup_file "$keyring_dropin"
write_root_file "$keyring_dropin" 0644 <<'EOF'
[Service]
KeyringMode=inherit
EOF
echo "-> Wrote $keyring_dropin"

install -d -m 0755 /etc/sddm.conf.d
autologin_conf="/etc/sddm.conf.d/10-autologin.conf"
backup_file "$autologin_conf"
write_root_file "$autologin_conf" 0644 <<EOF
[Autologin]
User=$target_user
Session=$target_session
Relogin=false
EOF
echo "-> Wrote $autologin_conf"

systemctl daemon-reload

echo
echo "Done. Reboot to test; do not restart SDDM from inside this graphical session."
