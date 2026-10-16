# GPU VRAM headroom on the RTX 5080

The lock-screen freezes and app hangs on the niri machines were traced to the
NVIDIA driver failing to allocate NVKMS memory (`Failed to allocate NVKMS
memory for GEM object` in the journal). The local inference engine keeps about
13.4 GiB of the 16 GiB resident, so the desktop stack, browser, and games
compete for very little VRAM. The fix is not to shrink the engine: keep the
session and displays on the 5080 and move non-critical applications to the
Radeon 610M iGPU (`card0`/`renderD129`) through reverse PRIME. The target is
roughly 1.5 GiB free on the 5080 at idle with everything running.

## Zen (flatpak)

The zen flatpak runtime ships both the Mesa (Radeon) and NVIDIA GL/Vulkan
drivers and a `radeonsi` VA-API driver, so the offload is a per-app override.
Inside the sandbox the paths differ from the host:

```sh
flatpak override --user app.zen_browser.zen \
  --env=__EGL_VENDOR_LIBRARY_FILENAMES=/usr/lib/x86_64-linux-gnu/GL/glvnd/egl_vendor.d/50_mesa.json \
  --env=LIBVA_DRIVER_NAME=radeonsi \
  --env='VK_LOADER_DRIVERS_DISABLE=*nvidia*'
```

Revert with `flatpak override --user --reset app.zen_browser.zen`. This alone
recovered on the order of 1 GiB.

## Jagex launcher and RuneLite

The Jagex launcher `.desktop` entries (both
`~/.local/share/applications/jagex-launcher*.desktop`) carry an `env` prefix on
their `Exec=` line; the launcher passes its environment on to the RuneLite
child process:

```ini
Exec=env __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json __GLX_VENDOR_LIBRARY_NAME=mesa LIBGL_ALWAYS_SOFTWARE=1 /home/dl/.local/bin/jagex-launcher-beta-linux-x86_64.AppImage %U
```

Launcher self-updates can rewrite these files, so re-apply the prefix if the
VRAM usage comes back.

RuneLite 1.13.x hardcodes its X11/GLX AWT toolkit, so it always renders through
XWayland, which lives on the session GPU (the 5080); EGL overrides and
`-Dawt.toolkit.name=WL` have no effect, and glvnd binds the X screen to the
NVIDIA client anyway (tens of `/dev/nvidia0` fds). Forcing Mesa GLX plus
software rendering with `LIBGL_ALWAYS_SOFTWARE=1` instead opens no render node
at all and cuts RuneLite's 5080 footprint from roughly 330-470 MiB to about
60 MiB of unavoidable XWayland window overhead. The price is that the OSRS GPU
plugin renders on the CPU via llvmpipe, which is fine at normal window sizes on
a Ryzen 610M-era CPU.

## Verifying

Free VRAM:

```sh
nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader
```

Which GPU a process actually renders on (render nodes held open):

```sh
ls -l /proc/<pid>/fd | grep -o '/dev/dri/renderD[0-9]*' | sort -u
```

`renderD128` is the 5080 and `renderD129` the iGPU. To confirm the lock
problem is gone, watch the journal while idling into an auto-lock:

```sh
journalctl -kf | grep --line-buffered NVKMS
```

Zero lines means the driver had enough headroom. See
[hyprlock-lockscreen.md](./hyprlock-lockscreen.md) for the lock-screen setup.
