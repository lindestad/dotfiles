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
    "$DOTFILES_DIR/config/fuzzel/fuzzel.ini|$HOME/.config/fuzzel/fuzzel.ini"
  )
}

ensure_noctalia_fedora() {
  if rpm -q noctalia-shell >/dev/null 2>&1; then
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

  [[ "${NIRI_LOCAL_MIGRATED:-no}" == "yes" ]] || return
  [[ -f "$local_config" ]] || return

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

install_niri_helpers() {
  ensure_local_bin

  local helper
  local helpers=(
    niri-focus-workspace-all
    niri-move-window-or-workspace
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
