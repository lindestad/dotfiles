#!/bin/bash
set -e

echo "[*] Detecting package manager..."

if command -v apt &> /dev/null; then
    PM="sudo apt install -y"
elif command -v pacman &> /dev/null; then
    PM="sudo pacman -S --noconfirm"
elif command -v dnf &> /dev/null; then
    PM="sudo dnf install -y"
else
    echo "[!] Unsupported package manager"
    exit 1
fi

echo "[*] Installing packages..."
$PM helix starship git zsh bash yazi nushell zellij

echo "[*] Symlinking config files..."
bash symlink.sh

echo "[✓] Setup complete!"