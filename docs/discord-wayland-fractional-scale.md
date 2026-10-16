# Discord Wayland Fractional-Scale Workaround

## Status: workaround in place, fix pending rollout

Read this before debugging any "Discord opens at the wrong size" report on the
side monitor, and before concluding that a niri window rule or output scale is
at fault.

## The Problem

The DP-2 side monitor runs at `scale 0.85` in `config/niri/local.kdl`. Native
Wayland Discord opens about 15% smaller than the size niri asked for there
(961x1062 instead of the intended 1116x1220 tile) and degrades further on each
restart: niri resizes the tile to the buffer Discord actually delivers, and
Discord re-persists that shrunken size into `WINDOW_BOUNDS` in
`~/.config/discord/settings.json`, which had drifted to its 800px minimum.

The bug is in Chromium's Wayland (Ozone) backend, which mishandles output
scale factors below 1.0. niri is correct: it sends `preferred_scale` 102/120
(exactly 0.85) and the right `configure` sizes, and every other toolkit sizes
correctly on that same monitor. On scale-1 outputs native Wayland Discord is
also fine. See the diagnosis session evidence kept out of tree under
`/tmp/opencode/dp2_trace.log` (WAYLAND_DEBUG trace, deleted on reboot).

## The Workaround

`~/.local/share/applications/discord.desktop` shadows the packaged entry and
runs Discord through xwayland-satellite instead, where the fractional-scale
negotiation does not exist:

```ini
Exec=/usr/bin/discord --ozone-platform=x11 --url -- %u
```

With it, Discord opens at the full tile size on every monitor (1113x1218 on
DP-2, 1266x1422 on the 1440p outputs).

## Upstream Status

- Root cause: [Chromium issue 438038776](https://issues.chromium.org/issues/438038776),
  closed as Fixed. Confirmed working at scale 0.8 with Chromium 154
  (report dated 2026-10-11).
- niri tracker: [niri#2770](https://github.com/niri-wm/niri/issues/2770)
  (closed, labeled `not niri:application`; duplicate of the older #3497).
  Accepted fix for Discord specifically is the `--ozone-platform=x11` flag.
- Discord 1.0.162 bundles Electron 42.11.12 / Chromium 148.0.7778.280, which
  predates the fix. It arrives whenever Discord ships an Electron with
  Chromium >= 154.

## Agent Instructions

Periodically (or when the user touches Discord sizing again) check whether
Discord now ships the fixed Chromium:

```sh
strings ~/.config/discord/app-*/Discord | grep -oE "Chrome/[0-9.]+" | sort -u
```

Once it reports Chromium >= 154:

1. Tell the user the upstream fix has landed and offer to remove the
   workaround: delete `~/.local/share/applications/discord.desktop`, run
   `update-desktop-database ~/.local/share/applications`, and reset
   `WINDOW_BOUNDS` in `~/.config/discord/settings.json` if it has drifted.
2. Relaunch Discord natively on DP-2 and confirm it opens near the full tile
   (~1114x1218) and that `WINDOW_BOUNDS` stays sane across a clean quit.
3. When the workaround is confirmed gone, delete this file and its line in
   the README, and commit.
