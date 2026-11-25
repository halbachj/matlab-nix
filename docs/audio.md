# MATLAB audio and external commands

This document covers two related issues on NixOS:

- MATLAB's bundled PortAudio not discovering the host's PipeWire ALSA output.
- External programs launched from MATLAB inheriting incompatible bundled
  libraries through `LD_LIBRARY_PATH`.

## Host package set is required on NixOS

Build MATLAB with the host NixOS package set:

```nix
matlab = inputs.matlab-nix.lib.mkMatlab {
  inherit pkgs;
  programsMatlab = { ... };
};
```

Do not pass only `system`. `mkMatlabPackages` then falls back to the flake's
pinned `nixpkgs`. That package set may not match the running system's package
set, while the FHS still reads host-provided configuration such as
`/etc/alsa/conf.d` and host graphics drivers. Mixing the two can cause:

- ALSA plugin load failures, for example a host PipeWire plugin requiring
  `ALSA_1.2.15` while the FHS provides a different `libasound`;
- graphics-acceleration failures when host Mesa drivers require a newer glibc.

If the flake input is used, also set:

```nix
matlab-nix.inputs.nixpkgs.follows = "nixpkgs";
```

`inherit pkgs` is still the important part: it preserves the host's overlays
and NixOS package configuration.

The flake's `packages.matlab` / `nix run .#matlab` use the flake's pinned
`nixpkgs`. They are useful for trying MATLAB, but they do not automatically
match the host audio or graphics stack.

## Why external commands fail

MathWorks' launcher prepends MATLAB's bundled library directories to
`LD_LIBRARY_PATH`:

```text
$MATLAB/sys/os/glnxa64:$MATLAB/bin/glnxa64:...
```

Programs started with `system()` inherit that path. They can then load MATLAB's
older bundled `libstdc++` instead of the host's newer one:

```text
libstdc++.so.6: version `GLIBCXX_3.4.32' not found
libstdc++.so.6: version `GLIBCXX_3.4.31' not found
libstdc++.so.6: version `CXXABI_1.3.15' not found
```

## Using `matlab-nix-exec`

The MATLAB wrapper captures the caller's `LD_LIBRARY_PATH` and `LD_PRELOAD`
before MathWorks' launcher runs. It installs `matlab-nix-exec` on `PATH` inside
the FHS. The helper restores the captured environment for the child process
only; MATLAB's own runtime is not changed. If no environment was captured (for
example, when the helper is run outside the MATLAB wrapper), it leaves the
environment unchanged.

Play a WAV file through PipeWire without inheriting MATLAB's bundled libraries:

```matlab
Fs = 48000;
t = (0:Fs-1)' / Fs;
y = 0.2 * sin(2 * pi * 440 * t);

filename = [tempname, '.wav'];
audiowrite(filename, y, Fs);

[status, output] = system( ...
    sprintf('matlab-nix-exec pw-play "%s"', filename));

disp(status);
disp(output);

delete(filename);
```

Any command can be used; arguments and the child's exit status are preserved.
For example:

```matlab
[status, output] = system('matlab-nix-exec aplay -L');
```

The helper is a normal shell command inside MATLAB's FHS, so it can also be
used from an interactive MATLAB terminal or from a script.

## Audio device discovery

MATLAB's bundled PortAudio enumerates ALSA hardware devices and configured PCMs.
When the host uses PipeWire and the FHS has a compatible `alsa-lib`,
`audiodevinfo` should include `pipewire` and `default`:

```matlab
info = audiodevinfo;
for k = 1:numel(info.output)
    fprintf('%d: %s (%s)\n', ...
        info.output(k).ID, info.output(k).Name, info.output(k).DriverVersion);
end
```

Typical output with PipeWire:

```text
0: HD-Audio Generic: HDMI 0 (hw:0,3) (ALSA)
...
5: pipewire (ALSA)
6: default (ALSA)
```

If those entries are missing while `speaker-test -D pipewire` works on the
host, the likely cause is the host plugin / FHS `alsa-lib` mismatch described
above. Rebuild with `inherit pkgs`.

### Playing through the default PipeWire output

`audioplayer` accepts a device ID. Use the `ID` reported by `audiodevinfo`:

```matlab
info = audiodevinfo;
idx = find(strcmp({info.output.Name}, 'default'), 1);
id = info.output(idx).ID;

Fs = 48000;
y = 0.2 * sin(2 * pi * 440 * (0:Fs-1)' / Fs);

player = audioplayer(y, Fs, 16, id);
play(player);
```

With `audioDeviceWriter`, select the device by name:

```matlab
writer = audioDeviceWriter('SampleRate', 48000, 'Device', 'default');
writer(y);
release(writer);
```

### `sound()` limitation

`sound()` does not expose a device argument:

```matlab
sound(y)
sound(y, Fs)
sound(y, Fs, nBits)
```

It may therefore choose the first hardware output instead of the PipeWire
default. Use `audioplayer(y, Fs, nBits, id)` or
`audioDeviceWriter(..., 'Device', 'default')` when routing matters. This is a
MATLAB API limitation, not a matlab-nix limitation.

## GStreamer for `audioread` and `audiowrite`

MATLAB's audio file I/O uses GStreamer 1.0. When it is unavailable,
`audioread` fails with:

```text
Error using audioread (line 153)
Audio file I/O requires Gstreamer 1.0 and higher.
Install this on your system and restart MATLAB.
```

GStreamer is not bundled by matlab-nix. Add it to the MATLAB FHS with
`programs.matlab.extraPkgs`:

```nix
programs.matlab.extraPkgs = with pkgs; [
  gst_all_1.gstreamer
  gst_all_1.gst-plugins-base
  gst_all_1.gst-plugins-good
];
```

The wrapper adds these packages to the FHS and sets
`GST_PLUGIN_SYSTEM_PATH_1_0` to their `lib/gstreamer-1.0` directories, so
GStreamer can find decoders such as `wavparse`. `gst-plugins-good` covers WAV;
add `gst-plugins-bad`, `gst-plugins-ugly`, or `gst-libav` for the formats they
provide (MP3, AAC, and others).

Rebuild the system or package and restart MATLAB after changing `extraPkgs`.
GStreamer caches its plugin registry, so the first start after a change can be
slower. Verify with:

```matlab
[y, fs] = audioread("myfile.wav");
```

## Troubleshooting

Check which `alsa-lib` the installed wrapper uses:

```console
nix path-info -r "$(readlink -f "$(command -v matlab)")" | grep alsa-lib
```

Compare it with the host's version:

```console
nix eval --raw nixpkgs#alsa-lib.version
```

If the FHS version is older than the host's and the host uses PipeWire, the
installation likely did not pass the host `pkgs`.

Check the host ALSA configuration:

```console
ls /etc/alsa/conf.d
```

For a PipeWire host, files such as `50-pipewire.conf` and
`99-pipewire-default.conf` define the `pipewire` and `default` PCMs.

Check PipeWire and the selected sink:

```console
wpctl status
speaker-test -D pipewire -c 2 -r 48000 -t sine
```

## Manual playback verification

Automated checks cannot verify Bluetooth routing or speaker output. To verify
manually:

1. Make the intended PipeWire sink the default, for example with
   `wpctl status` and `wpctl set-default <id>`.
2. Start MATLAB from the configured wrapper.
3. Run `audiodevinfo` and confirm that `default` is listed.
4. Play a tone with `audioplayer` and the `default` device ID; confirm it is
   audible through the intended output.
5. Run `system('matlab-nix-exec pw-play /path/to/file.wav')` and confirm the
   exit status is zero and audio is audible.