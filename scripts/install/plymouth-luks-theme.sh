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

patch_theme_script() {
  local script_path="$theme_dst/$theme_name.script"

  cat >"$script_path" <<'EOF'
## Author : Aditya Shakya (adi1090x)
## Mail : adi1090x@gmail.com
## Github : @adi1090x
## Reddit : @adi1090x
## Local changes: center layout consistently and use password bullets.

// Screen size
screen.x = Window.GetX();
screen.y = Window.GetY();
screen.w = Window.GetWidth();
screen.h = Window.GetHeight();
screen.center.x = screen.x + screen.w / 2;
screen.center.y = screen.y + screen.h / 2;

// Question prompt
question = null;
answer = null;

// Message
message = null;

// Password prompt
bullets = null;
prompt = null;
bullet.image = Image.Text("•", 1, 1, 1);

// Flow
state.status = "play";
state.time = 0.0;

//--------------------------------- Refresh (Logo animation) --------------------------

# cycle through all images
for (i = 0; i < 119; i++)
  flyingman_image[i] = Image("progress-" + i + ".png");
flyingman_sprite = Sprite();

# set image position
flyingman_sprite.SetX(screen.center.x - flyingman_image[0].GetWidth() / 2);
flyingman_sprite.SetY(screen.center.y - flyingman_image[0].GetHeight() / 2);

progress = 0;

fun refresh_callback ()
  {
    frame = flyingman_image[Math.Int(progress / 2) % 119];
    flyingman_sprite.SetImage(frame);
    flyingman_sprite.SetX(screen.center.x - frame.GetWidth() / 2);
    flyingman_sprite.SetY(screen.center.y - frame.GetHeight() / 2);
    progress++;
  }

Plymouth.SetRefreshFunction (refresh_callback);

//------------------------------------- Question prompt -------------------------------
fun DisplayQuestionCallback(prompt, entry) {
    question = null;
    answer = null;

    if (entry == "")
        entry = "<answer>";

    question.image = Image.Text(prompt, 1, 1, 1);
    question.sprite = Sprite(question.image);
    question.sprite.SetX(screen.center.x - question.image.GetWidth() / 2);
    question.sprite.SetY(screen.center.y + 210);

    answer.image = Image.Text(entry, 1, 1, 1);
    answer.sprite = Sprite(answer.image);
    answer.sprite.SetX(screen.center.x - answer.image.GetWidth() / 2);
    answer.sprite.SetY(screen.center.y + 250);
}
Plymouth.SetDisplayQuestionFunction(DisplayQuestionCallback);

//------------------------------------- Password prompt -------------------------------
fun DisplayPasswordCallback(nil, bulletCount) {
    state.status = "pause";
    totalWidth = bulletCount * bullet.image.GetWidth();
    startPos = screen.center.x - totalWidth / 2;

    prompt.image = Image.Text("Enter Password", 1, 1, 1);
    prompt.sprite = Sprite(prompt.image);
    prompt.sprite.SetX(screen.center.x - prompt.image.GetWidth() / 2);
    prompt.sprite.SetY(screen.center.y + 210);

    // Clear all bullets (user might hit backspace)
    bullets = null;
    for (i = 0; i < bulletCount; i++) {
        bullets[i].sprite = Sprite(bullet.image);
        bullets[i].sprite.SetX(startPos + i * bullet.image.GetWidth());
        bullets[i].sprite.SetY(screen.center.y + 250);
    }
}
Plymouth.SetDisplayPasswordFunction(DisplayPasswordCallback);

//--------------------------- Normal display (unset all text) ----------------------
fun DisplayNormalCallback() {
    state.status = "play";
    bullets = null;
    prompt = null;
    message = null;
    question = null;
    answer = null;
}
Plymouth.SetDisplayNormalFunction(DisplayNormalCallback);

//----------------------------------------- Message --------------------------------
fun MessageCallback(text) {
    message.image = Image.Text(text, 1, 1, 1);
    message.sprite = Sprite(message.image);
    message.sprite.SetPosition(screen.center.x - message.image.GetWidth() / 2, screen.y + message.image.GetHeight());
}
Plymouth.SetMessageFunction(MessageCallback);
EOF
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
patch_theme_script

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
