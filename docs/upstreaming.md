# Upstreaming / redistribution preparation

This document captures what a maintainer must resolve before publishing this
project or proposing it upstream (e.g. to nixpkgs or a public flake registry).
The code itself is in a publishable state; the items below are policy,
licensing, and packaging decisions that are intentionally left for the owner.

## 1. Licensing

- MATLAB is proprietary **unfree** software distributed by MathWorks under its
  own license terms. The `meta.license` of every package is set to `unfree`.
- The *packaging code* in this repository is separate from MATLAB binaries.
  Decide and state a license for the code (e.g. MIT / Apache-2.0) and add a
  `LICENSE` file. The current `meta` does **not** declare a code license.
- Confirm redistribution of the packaging code is compatible with MathWorks
  terms. This project fetches installers from `www.mathworks.com` at build time
  and publishes **no binary cache**; it does not redistribute MATLAB artifacts.

## 2. Binary cache / distribution

- No binary cache is published. If this is later hosted on a Nix binary cache,
  add a `meta.nixpkgs-fetch-info` / cache note and remove the "no binary cache"
  wording in `flake.nix` (`mkMeta`).

## 3. Reproducibility of install packages

- `mpm install` is interactive and network-dependent. `tests/build.nix` exists
  but is intentionally **not** part of `checks`, so `nix flake check` does not
  require downloads. Decide whether CI should ever run a real install build.

## 4. nixpkgs integration

If proposing to nixpkgs:

- The FHS wrappers (`lib/fhs.nix`) rely on host mounts (`/dev`, `/proc`,
  `/sys`, `/tmp`, `/home`) that may not be acceptable as default nixpkgs
  packages — review against nixpkgs conventions.
- `programs.matlab` module needs `specialArgs` `{ matlabProducts,
  productMetadata }`; when importing into nixpkgs, prefer exposing them via
  `_module.args` or moving metadata into the module.
- `meta.platforms` is currently hard-coded to `[ "x86_64-linux" ]`; keep in
  sync with the metadata actually available.

## 5. Security review

- The module validates product/release/dependency selections at evaluation time
  (`throw`), preventing unknown releases, unknown keys, duplicate selections,
  and incomplete dependency closures.
- Fixed-output fetches pin Nix SRI hashes for every product archive.
- Review the FHS `extraMounts` and `extraBwrapArgs` before publishing; they
  grant broad host access inside the sandbox (required for MATLAB IPC and
  license resolution) and should be documented for users.

## 6. Housekeeping before publishing

- [ ] Add `LICENSE` and update the `meta` license note in `flake.nix`.
- [ ] Run `nix flake check --all-systems`.
- [ ] Confirm `git status` is clean and `flake.lock` is current.
- [ ] Review `README.md` usage/status warnings for accuracy.
