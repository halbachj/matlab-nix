# matlab-nix

MATLAB packaging for Nix: MPM downloads, install, and FHS GUI wrappers.

This flake builds and runs MATLAB (and optional MathWorks products) on
`x86_64-linux` by downloading the official MathWorks installers at build time
via the MathWorks Package Manager (`mpm`). It exposes:

- a public, release-independent product catalog (`matlabProducts`),
- a NixOS module (`programs.matlab`) for selecting a release and products with
  evaluation-time validation, and
- per-system packages, checks, and dev shells.

## Status / warnings

- MATLAB is **unfree**; `allowUnfree` is required.
- Artifacts are fetched directly from MathWorks during the build; this project
  publishes **no binary cache**.
- `mpm install` runs interactively and is not fully reproducible in CI; the
  `matlab*` packages are therefore intentionally **not** wired into `flake
  checks` (see `tests/build.nix`).
- The MATLAB Connector wrapper is **experimental** and is not part of the
  minimal default.

## Usage

```console
# Minimal MATLAB (FHS wrapper)
nix run .#matlab

# MATLAB + Simulink example
nix run .#matlabWithSimulink

# MATLAB + Simulink + image/signal processing toolboxes
nix run .#matlabWithToolboxes

# MathWorks Service Host
nix run .#serviceHost
```

`nix develop` shells are provided as `.#devShells.default` (MPM toolchain) and
`.#devShells.matlab` / `.#devShells.serviceHost` (the FHS wrappers).

## Packages

| Package | Description |
| --- | --- |
| `default` / `matlab` | MATLAB under an FHS sandbox (minimal default) |
| `matlabRaw` | Raw MATLAB install tree from MPM sources (no FHS wrapper) |
| `serviceHost` | MathWorks Service Host under an FHS sandbox |
| `serviceHostWindow` | Service Host window under an FHS sandbox |
| `matlabWithSimulink` | MATLAB + Simulink example |
| `matlabWithToolboxes` | MATLAB + Simulink + toolboxes example |
| `connector` | **Experimental** MATLAB Connector wrapper |

## NixOS module

Enable the module and select products:

```nix
{
  imports = [ matlab-nix.nixosModules.matlab ];

  programs.matlab = {
    release = "R2026a";
    installedProducts = [ "matlab" "simulink" "imageProcessing" ];
  };
}
```

Product keys are the names of the `matlabProducts` catalog (e.g. `matlab`,
`simulink`, `imageProcessing`, `signalProcessing`). At evaluation time the
module validates that:

- the configured `release` exists in `lib/products.nix`,
- every selected key is defined in `lib/matlabProducts.nix`,
- every selected product is available in the configured release, and
- there are no duplicate selections and the dependency closure is complete.

Invalid selections fail the build with a descriptive `throw`.

## Architecture

The project is split into independent layers so each concern can be tested and
maintained separately:

| Layer | File | Responsibility |
| --- | --- | --- |
| Product catalog | `lib/matlabProducts.nix` | Release-independent named catalog (public `matlabProducts`) |
| Release metadata | `lib/products.nix` | Per-release checksum + product table (names, codes, hashes, dependencies) |
| Selection/validation | `modules/matlab.nix` | `programs.matlab` options + eval-time validation |
| MPM toolchain | `modules/mpm.nix` | The `mpm` binary and its FHS shell |
| Download | `lib/fetchMpm.nix` | Fixed-output fetch of each product archive |
| Install | `lib/install.nix` | Merge sources + `mpm install`; FHS-independent |
| Service Host | `lib/serviceHost.nix` | MathWorks Service Host derivation |
| GUI wrappers | `lib/fhs.nix` | FHS sandboxes that launch MATLAB / Service Host / Connector |
| Wiring | `flake.nix` | Public outputs, package resolution, meta, checks |
| Tests | `tests/checks.nix` | Eval-time closure assertions (`nix flake check`) |

## Maintenance

- **Adding a release / product**: edit `lib/products.nix` (checksum + product
  table) and, if a new named product is needed, `lib/matlabProducts.nix`.
  Hashes are Nix SRI hashes of the MPM product archives.
- **Validation**: run `nix flake check` (fast, no downloads; runs the
  `tests/checks.nix` closure assertions).
- **Full build**: `nix build .#matlab` requires network access to MathWorks and
  is intentionally excluded from `flake check`.

## License

MATLAB is proprietary software (unfree); see the `meta.license` of each package.
The packaging code in this repository is licensed under the BSD 3-Clause License —
see `LICENSE`. See `docs/upstreaming.md` for redistribution guidance.
