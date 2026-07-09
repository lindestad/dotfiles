#!/usr/bin/env bash
# Niri desktop install helpers. Source from scripts/install/common.sh.

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  echo "!! scripts/install/desktop-niri.sh is a helper; run ./install.sh instead."
  exit 1
fi

NIRI_LOCAL_MIGRATED="no"

add_wayland_desktop_links() {
  LINKS+=(
    "$DOTFILES_DIR/config/niri/config.kdl|$HOME/.config/niri/config.kdl"
    "$DOTFILES_DIR/config/niri/keybinds.kdl|$HOME/.config/niri/keybinds.kdl"
    "$DOTFILES_DIR/config/niri/local.example.kdl|$HOME/.config/niri/local.example.kdl"
    "$DOTFILES_DIR/config/hypr/hyprlock.conf|$HOME/.config/hypr/hyprlock.conf"
    "$DOTFILES_DIR/config/xkb/symbols/usno|$HOME/.config/xkb/symbols/usno"
    "$DOTFILES_DIR/config/fuzzel/fuzzel.ini|$HOME/.config/fuzzel/fuzzel.ini"
    "$DOTFILES_DIR/config/noctalia/monochrome-strong.json|$HOME/.config/noctalia/colorschemes/monochrome-strong/monochrome-strong.json"
  )
}

ensure_noctalia_fedora() {
  if rpm -q noctalia-shell >/dev/null 2>&1 || rpm -q noctalia-shell-legacy >/dev/null 2>&1; then
    return
  fi

  if dnf -q list --available noctalia-shell >/dev/null 2>&1; then
    install_dnf noctalia-shell
    return
  fi

  echo ">> Noctalia Shell is not available from the configured Fedora repositories."
  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping Terra repository setup in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Install Terra repository and Noctalia Shell?")" != "yes" ]]; then
    return
  fi

  echo "==> Installing Terra repository..."
  sudo dnf install -y --nogpgcheck \
    --repofrompath "terra,https://repos.fyralabs.com/terra\$releasever" \
    terra-release
  # shellcheck disable=SC2034
  DNF_MAKECACHE_DONE="no"
  install_dnf noctalia-shell
}

ensure_power_profiles_fedora() {
  if rpm -q power-profiles-daemon >/dev/null 2>&1; then
    return
  fi

  if rpm -q tuned-ppd >/dev/null 2>&1; then
    echo ">> Skipping power-profiles-daemon; tuned-ppd is installed and provides the power profile service."
    return
  fi

  install_dnf power-profiles-daemon
}

ensure_nirimod() {
  if have nirimod; then
    echo "-> NiriMod already installed: $(command -v nirimod)"
    return
  fi

  echo "==> Installing NiriMod..."

  if have pacman; then
    local helper=""
    if helper="$(aur_helper 2>/dev/null)"; then
      if "$helper" -S --needed --noconfirm nirimod-git && have nirimod; then
        return
      fi
      echo ">> Could not install nirimod-git from AUR; falling back to the upstream installer."
    else
      echo ">> No AUR helper found; using the upstream NiriMod installer."
    fi
  fi

  if ! have curl; then
    echo "!! curl is required to install NiriMod from upstream."
    return
  fi

  local installer
  installer="$(mktemp)"
  if ! curl -fsSL https://raw.githubusercontent.com/srinivasr/nirimod/main/install.sh -o "$installer"; then
    echo "!! Could not download the NiriMod installer."
    rm -f "$installer"
    return
  fi

  if ! bash "$installer" --install; then
    echo "!! NiriMod installer failed; continuing without NiriMod."
    rm -f "$installer"
    return
  fi

  rm -f "$installer"
  if have nirimod; then
    echo "-> Installed NiriMod: $(command -v nirimod)"
  else
    echo "!! NiriMod installer completed, but nirimod is not on PATH."
  fi
}

noctalia_apt_suite() {
  local codename=""

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    codename="${VERSION_CODENAME:-${UBUNTU_CODENAME:-}}"
  fi

  case "$codename" in
    trixie|sid|plucky|questing)
      printf '%s\n' "$codename"
      ;;
    *)
      return 1
      ;;
  esac
}

ensure_noctalia_ubuntu() {
  local suite key_file

  if dpkg-query -W -f='${Status}' noctalia-shell 2>/dev/null | grep -q "install ok installed"; then
    return
  fi

  if apt-cache show noctalia-shell >/dev/null 2>&1; then
    install_apt noctalia-shell
    return
  fi

  if ! suite="$(noctalia_apt_suite)"; then
    echo ">> Noctalia Shell APT packages are only configured for Debian trixie/sid and Ubuntu plucky/questing."
    echo ">> Skipping Noctalia Shell package setup for this distro release."
    return
  fi

  if [[ "$ASSUME_YES" == "yes" ]]; then
    echo ">> Skipping Noctalia APT repository setup in non-interactive mode."
    return
  fi
  if [[ "$(prompt_yes_no "Add Noctalia APT repository for $suite and install Noctalia Shell?")" != "yes" ]]; then
    return
  fi

  echo "==> Adding Noctalia APT repository..."
  sudo install -d -m 0755 /etc/apt/keyrings
  key_file="$(mktemp)"
  curl -fsSL https://pkg.noctalia.dev/gpg.key -o "$key_file"
  sudo gpg --yes --dearmor -o /etc/apt/keyrings/noctalia.gpg "$key_file"
  rm -f "$key_file"
  echo "deb [signed-by=/etc/apt/keyrings/noctalia.gpg] https://pkg.noctalia.dev/apt $suite main" \
    | sudo tee /etc/apt/sources.list.d/noctalia.list >/dev/null
  install_apt noctalia-shell
}

extract_niri_local_config() {
  local src="$1" dst="$2" tmp

  [[ -f "$src" ]] || return 1

  tmp="$(mktemp)"
  if ! perl -Mutf8 -CS - "$src" "$tmp" <<'PERL'
use strict;
use warnings;

my ($src, $dst) = @ARGV;
open my $fh, "<:encoding(UTF-8)", $src or die "$src: $!";
my @lines = <$fh>;
close $fh;

sub brace_delta {
  my ($line) = @_;
  $line =~ s{//.*$}{};
  my $open = () = $line =~ /\{/g;
  my $close = () = $line =~ /\}/g;
  return $open - $close;
}

sub block_end {
  my ($start) = @_;
  my $depth = 0;
  for my $i ($start .. $#lines) {
    $depth += brace_delta($lines[$i]);
    return $i if $depth <= 0 && $i > $start;
  }
  return;
}

my @out;
my @debug;

for (my $i = 0; $i <= $#lines; $i++) {
  my $line = $lines[$i];

  if ($line =~ /^\s*output\s+"/) {
    my $end = block_end($i);
    next unless defined $end;
    push @out, "\n" if @out && $out[-1] !~ /^\s*$/;
    push @out, @lines[$i .. $end];
    $i = $end;
    next;
  }

  if ($line =~ /^\s*debug\s*\{/) {
    my $end = block_end($i);
    next unless defined $end;
    for my $j ($i + 1 .. $end - 1) {
      my $check = $lines[$j];
      $check =~ s{//.*$}{};
      next unless $check =~ /\b(render-drm-device|wait-for-frame-completion-before-queueing)\b/;
      $check =~ s/^\s+|\s+$//g;
      push @debug, "    $check\n" if length $check;
    }
    $i = $end;
  }
}

if (@debug) {
  push @out, "\n" if @out && $out[-1] !~ /^\s*$/;
  push @out, "debug {\n", @debug, "}\n";
}

exit 1 unless @out;

open my $out_fh, ">:encoding(UTF-8)", $dst or die "$dst: $!";
print {$out_fh} "// Migrated from existing niri config by the dotfiles installer.\n\n";
print {$out_fh} @out;
close $out_fh;
PERL
  then
    rm -f "$tmp"
    return 1
  fi

  mv "$tmp" "$dst"
}

prepare_niri_config_dir() {
  local niri_dir="$HOME/.config/niri"
  local ts local_tmp="" local_tmp_kind=""

  NIRI_LOCAL_MIGRATED="no"

  mkdir -p "$HOME/.config"

  if [[ -L "$niri_dir" ]]; then
    if [[ -e "$niri_dir/local.kdl" ]]; then
      local_tmp="$(mktemp)"
      cp -pL "$niri_dir/local.kdl" "$local_tmp"
      local_tmp_kind="existing"
    elif [[ -f "$niri_dir/config.kdl" ]]; then
      local_tmp="$(mktemp)"
      if extract_niri_local_config "$niri_dir/config.kdl" "$local_tmp"; then
        local_tmp_kind="migrated"
      else
        rm -f "$local_tmp"
        local_tmp=""
      fi
    fi

    ts="$(date +%Y%m%d-%H%M%S)"
    mv -v "$niri_dir" "${niri_dir}.bak.${ts}"
    mkdir -p "$niri_dir"

    if [[ -n "$local_tmp" ]]; then
      cp -p "$local_tmp" "$niri_dir/local.kdl"
      rm -f "$local_tmp"
      if [[ "$local_tmp_kind" == "migrated" ]]; then
        NIRI_LOCAL_MIGRATED="yes"
        echo "-> Migrated existing Niri output settings to $niri_dir/local.kdl"
      else
        echo "-> Preserved existing Niri local config: $niri_dir/local.kdl"
      fi
    fi
    return
  fi

  if [[ -e "$niri_dir" && ! -d "$niri_dir" ]]; then
    ts="$(date +%Y%m%d-%H%M%S)"
    mv -v "$niri_dir" "${niri_dir}.bak.${ts}"
  fi

  mkdir -p "$niri_dir"

  if [[ ! -e "$niri_dir/local.kdl" && -f "$niri_dir/config.kdl" ]]; then
    if extract_niri_local_config "$niri_dir/config.kdl" "$niri_dir/local.kdl"; then
      NIRI_LOCAL_MIGRATED="yes"
      echo "-> Migrated existing Niri output settings to $niri_dir/local.kdl"
    fi
  fi
}

validate_migrated_niri_local_config() {
  local niri_config="$HOME/.config/niri/config.kdl"
  local local_config="$HOME/.config/niri/local.kdl"
  local ts

  [[ "${NIRI_LOCAL_MIGRATED:-no}" == "yes" ]] || return 0
  [[ -f "$local_config" ]] || return 0

  if ! have niri; then
    echo ">> Skipping migrated Niri local config validation; niri is not installed."
    return
  fi

  if niri validate -c "$niri_config"; then
    return
  fi

  ts="$(date +%Y%m%d-%H%M%S)"
  mv -v "$local_config" "${local_config}.invalid.${ts}"
  echo ">> Migrated Niri local config did not validate and was disabled."
  niri validate -c "$niri_config" || true
}

activate_niri_usno_layout() {
  local target_name="US with Norwegian on AltGr"
  local layouts original_idx original_name target_idx current_idx after after_idx after_name
  local restored restored_idx restored_name

  if ! have niri; then
    return
  fi

  if ! have jq; then
    echo ">> Skipping Niri keyboard layout activation; jq is not installed."
    return
  fi

  if ! layouts="$(niri msg -j keyboard-layouts 2>/dev/null)"; then
    return
  fi

  original_idx="$(jq -r '.current_idx // empty' <<<"$layouts")"
  original_name="$(jq -r --arg idx "$original_idx" '.names[$idx | tonumber] // "unknown"' <<<"$layouts" 2>/dev/null || true)"

  niri msg action load-config-file >/dev/null 2>&1 || true
  sleep 0.2

  if ! layouts="$(niri msg -j keyboard-layouts 2>/dev/null)"; then
    echo ">> Niri config reload was requested, but keyboard layout status could not be read afterward."
    return
  fi

  target_idx="$(jq -r --arg target "$target_name" '.names | to_entries[] | select(.value == $target) | .key' <<<"$layouts" | head -n 1)"
  current_idx="$(jq -r '.current_idx // empty' <<<"$layouts")"

  if [[ -z "$target_idx" ]]; then
    echo ">> Niri config reloaded, but the running session did not expose '$target_name'."
    echo ">> Restart Niri to activate the new XKB layout. Current layout remains: ${original_name:-unknown}."
    return
  fi

  if [[ "$current_idx" == "$target_idx" ]]; then
    echo "-> Niri keyboard layout already active: $target_name"
    return
  fi

  if ! niri msg action switch-layout "$target_idx" >/dev/null 2>&1; then
    echo "!! Failed to switch Niri keyboard layout to '$target_name'."
    return
  fi

  after="$(niri msg -j keyboard-layouts 2>/dev/null || true)"
  after_idx="$(jq -r '.current_idx // empty' <<<"$after" 2>/dev/null || true)"
  after_name="$(jq -r --arg idx "$after_idx" '.names[$idx | tonumber] // "unknown"' <<<"$after" 2>/dev/null || true)"

  if [[ "$after_idx" == "$target_idx" ]]; then
    echo "-> Niri keyboard layout set to: $target_name"
    return
  fi

  echo "!! Niri keyboard layout switch landed on '${after_name:-unknown}' instead of '$target_name'."
  if [[ "$original_idx" =~ ^[0-9]+$ ]] && niri msg action switch-layout "$original_idx" >/dev/null 2>&1; then
    restored="$(niri msg -j keyboard-layouts 2>/dev/null || true)"
    restored_idx="$(jq -r '.current_idx // empty' <<<"$restored" 2>/dev/null || true)"
    restored_name="$(jq -r --arg idx "$restored_idx" '.names[$idx | tonumber] // "unknown"' <<<"$restored" 2>/dev/null || true)"
    if [[ "$restored_idx" == "$original_idx" ]]; then
      echo "-> Restored original Niri keyboard layout: ${restored_name:-$original_name}"
      return
    fi
  fi

  echo "!! Could not restore original Niri keyboard layout. Current layout may be: ${after_name:-unknown}."
}

install_niri_helpers() {
  ensure_local_bin

  local helper
  local helpers=(
    niri-focus-workspace-all
    niri-lock-screen
    niri-move-window-or-workspace
    niri-screenshot-region
    noctalia-activate-notification
  )

  for helper in "${helpers[@]}"; do
    if [[ ! -f "$DOTFILES_DIR/bin/$helper" ]]; then
      echo "!! Missing Niri helper: $DOTFILES_DIR/bin/$helper"
      continue
    fi

    install -m 0755 "$DOTFILES_DIR/bin/$helper" "$HOME/.local/bin/$helper"
    echo "-> Installed Niri helper: ~/.local/bin/$helper"
  done
}
