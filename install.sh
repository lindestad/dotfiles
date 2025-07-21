#!/usr/bin/env bash

echo "[*] Detecting package manager..."

if command -v apt &> /dev/null; then
    PM="sudo apt install -y"
    PACKAGES=(
        helix starship eza ripgrep fd-find ffmpeg p7zip-full jq bat fzf
        zoxide imagemagick yazi nushell git zellij coreutils ncspot
    )
elif command -v pacman &> /dev/null; then
    PM="sudo pacman -S --noconfirm"
    PACKAGES=(
        helix starship eza ripgrep fd ffmpeg p7zip jq bat fzf zoxide
        imagemagick yazi nushell git zellij coreutils ncspot
    )
elif command -v dnf &> /dev/null; then
    PM="sudo dnf install -y"
    PACKAGES=(
        helix starship eza ripgrep fd-find ffmpeg p7zip jq bat fzf zoxide
        ImageMagick yazi nushell git zellij coreutils ncspot
    )
else
    echo "[!] Unsupported package manager"
    exit 1
fi

echo "[*] Installing packages..."
FAILED=()

for pkg in "${PACKAGES[@]}"; do
    if $PM "$pkg" &> /dev/null; then
        echo "  [✓] $pkg"
    else
        echo "  [✗] $pkg (failed)"
        FAILED+=("$pkg")
    fi
done

echo "[*] Symlinking config files..."
bash "$(dirname "$0")/symlink.sh"

echo "[✓] Setup complete."

if (( ${#FAILED[@]} > 0 )); then
    echo ""
    echo "[!] The following packages failed to install:"
    for f in "${FAILED[@]}"; do
        echo "  - $f"
    done
    echo "You may need to install them manually."
fi
