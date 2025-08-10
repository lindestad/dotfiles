#!/usr/bin/env bash
set -euo pipefail

# Resolve target user/home even if invoked via sudo
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
KANATA_BIN="$(command -v kanata || true)"
KANATA_CFG="${KANATA_CFG:-$TARGET_HOME/.config/kanata/config.kbd}"

echo "==> User: $TARGET_USER"
echo "==> Home: $TARGET_HOME"

echo "==> Ensure groups & memberships…"
# Create uinput group if missing
if ! getent group uinput >/dev/null; then
  sudo groupadd uinput
  echo "   created group: uinput"
fi

# Add user to input/uinput (idempotent)
for grp in input uinput; do
  if id -nG "$TARGET_USER" | grep -qw "$grp"; then
    echo "   $TARGET_USER already in $grp"
  else
    sudo gpasswd -a "$TARGET_USER" "$grp"
  fi
done

echo "==> Ensure uinput module loads at boot…"
MODULES_FILE="/etc/modules-load.d/uinput.conf"
if [[ ! -f "$MODULES_FILE" ]] || ! grep -qx "uinput" "$MODULES_FILE"; then
  echo uinput | sudo tee "$MODULES_FILE" >/dev/null
  echo "   wrote $MODULES_FILE"
else
  echo "   $MODULES_FILE already contains uinput"
fi

echo "==> Set udev permissions for /dev/uinput…"
UDEV_RULE="/etc/udev/rules.d/90-uinput.rules"
RULE_LINE='KERNEL=="uinput", GROUP="uinput", MODE="0660", OPTIONS+="static_node=uinput"'
if [[ ! -f "$UDEV_RULE" ]] || ! grep -qxF "$RULE_LINE" "$UDEV_RULE"; then
  echo "$RULE_LINE" | sudo tee "$UDEV_RULE" >/dev/null
  echo "   wrote $UDEV_RULE"
else
  echo "   $UDEV_RULE already present"
fi

echo "==> Reload udev & (re)load module…"
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo modprobe uinput || true
ls -l /dev/uinput || echo "   (node may appear when first opened)"

# Prompt for service setup
read -r -p "Install & enable Kanata systemd user service for $TARGET_USER? [y/N] " REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  echo "==> Setting up systemd --user service…"

  # Sanity checks
  if [[ -z "$KANATA_BIN" ]]; then
    echo "!! 'kanata' not found in PATH. Install it (e.g. yay -S kanata or kanata-bin) and re-run."
    exit 1
  fi
  if [[ ! -f "$KANATA_CFG" ]]; then
    echo "!! Kanata config not found at: $KANATA_CFG"
    echo "   Create it or set KANATA_CFG=/path/to/config.kbd and re-run."
    exit 1
  fi

  UNIT_DIR="$TARGET_HOME/.config/systemd/user"
  sudo -u "$TARGET_USER" mkdir -p "$UNIT_DIR"

  UNIT_PATH="$UNIT_DIR/kanata.service"
  cat <<'UNIT' | sudo -u "$TARGET_USER" tee "$UNIT_PATH" >/dev/null
[Unit]
Description=Kanata keyboard remapper
Wants=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
# Wait until /dev/uinput is present (some systems create it lazily)
ExecStartPre=/usr/bin/sh -c 'for i in $(seq 1 25); do [ -e /dev/uinput ] && exit 0; sleep 0.2; done; echo "/dev/uinput missing" >&2; exit 1'
ExecStart=/usr/bin/kanata -c %h/.config/kanata/config.kbd
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
UNIT

  # Adjust ExecStart if kanata is not at /usr/bin/kanata
  if [[ "$KANATA_BIN" != "/usr/bin/kanata" && -n "$KANATA_BIN" ]]; then
    sudo -u "$TARGET_USER" sed -i "s|^ExecStart=/usr/bin/kanata|ExecStart=${KANATA_BIN}|" "$UNIT_PATH"
  fi

  echo "   wrote $UNIT_PATH"

  # Robust enablement without requiring an interactive user bus
  UID_NUM="$(id -u "$TARGET_USER")"
  BUS_SOCKET="/run/user/${UID_NUM}/bus"

  # Ensure a user manager exists; enable lingering and start user@ if needed
  if [[ ! -S "$BUS_SOCKET" ]]; then
    sudo loginctl enable-linger "$TARGET_USER" >/dev/null 2>&1 || true
    sudo systemctl start "user@${UID_NUM}.service" >/dev/null 2>&1 || true
  fi

  SCMD=(systemctl --user --machine="$TARGET_USER@.host")

  # Try to talk to user manager; if it fails, fall back to static enable (symlink)
  if "${SCMD[@]}" daemon-reload >/dev/null 2>&1; then
    "${SCMD[@]}" enable kanata.service >/dev/null 2>&1 || true
    "${SCMD[@]}" start kanata.service  >/dev/null 2>&1 || true
    # Optional status only if bus/socket exists
    if [[ -S "$BUS_SOCKET" ]]; then
      "${SCMD[@]}" status --no-pager kanata.service || true
    fi
  else
    # Fallback: create wants symlink so it starts on next user session
    WANTS_DIR="$UNIT_DIR/graphical-session.target.wants"
    sudo -u "$TARGET_USER" mkdir -p "$WANTS_DIR"
    sudo -u "$TARGET_USER" ln -sf "$UNIT_PATH" "$WANTS_DIR/kanata.service"
    echo "   (No user bus; enabled via wants symlink. It will start on next login.)"
  fi

  echo "==> If groups were just added, log out/in (or reboot) so they take effect."
else
  echo "==> Skipping systemd user service."
fi

echo "==> Done."
