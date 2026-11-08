# Changelog

All notable changes to this project are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versions follow
the title's `contentVersion` in `sce_sys/param.json`, and each release is
tagged with it.

## [01.000.000] - 2026-11-08

First public release: DK64: Recompiled v1.0.3 as a native PS5 title.

### Added
- Native title `PPSA64064`, "DK64 Rekongpiled", rendering with RT64 through
  Vulkan on Mihawk's RADV port, output at 3840x2160 and interpolated to 60 fps.
- The game starts straight away: the ROM is imported from the title folder on
  the first start; settings, saves and mods are kept there. Without a usable
  ROM, a screen says where to put it.
- The touchpad opens the menu, made for the console: PlayStation button
  prompts, Framerate as Original (30) or 60, and no PC-only options, Find Mods
  tab or multiplayer switch.
- Tag Anywhere 1.0.3 and Tag Anywhere Sparkles 1.0.1 built in, switched on.
- Texture packs and code mods from `mods/`; code mod switches apply on the
  next start.
- Performance Overlay option (Graphics tab).
- Follow Cam as the default camera.
- Home screen icon, background and start-up splash.
- `dk64.log` in the title folder with the start-up steps, errors and crash
  reports; the previous session's log is kept as `dk64.prev.log`.
