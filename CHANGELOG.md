# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Unreleased

### Fixed

- External applications launched from MATLAB can encounter incompatible shared
  libraries because MathWorks prepends its bundled library directories to
  `LD_LIBRARY_PATH`. The MATLAB wrapper now captures the caller's
  `LD_LIBRARY_PATH` and `LD_PRELOAD`, and the new `matlab-nix-exec` helper
  restores them for child processes.

### Added

- `matlab-nix-exec`, available on `PATH` inside the MATLAB FHS, for launching
  arbitrary external commands with the pre-MATLAB linker environment.
- Tests for environment capture, unset/empty/populated `LD_LIBRARY_PATH`,
  argument preservation, exit-status propagation, parent-environment isolation,
  and helper availability in the FHS.
- `docs/audio.md` with PipeWire/ALSA device detection, playback examples, and
  troubleshooting steps.

### Changed

- The MATLAB FHS launcher captures the original linker environment before
  running MathWorks' launcher.
- Documented that NixOS installations must build MATLAB with the host `pkgs`
  (`inherit pkgs`). Without it, the FHS uses the flake's pinned `nixpkgs`, which
  can mismatch host ALSA plugins and graphics drivers.

### Audio compatibility

- Documented the root cause of missing `default`/`pipewire` devices: the host's
  PipeWire ALSA plugin can require a newer ALSA symbol version than the
  FHS-provided `alsa-lib`. With the host package set, `audiodevinfo` exposes
  `default` and `pipewire`, and `audioplayer` /
  `audioDeviceWriter('Device', 'default')` can play through the host's PipeWire
  output.
- `sound()` still has no device-selection argument and may choose the first
  hardware device. Use `audioplayer` or `audioDeviceWriter` when routing must be
  deterministic.