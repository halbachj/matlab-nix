# Builds the raw MATLAB install tree from merged MPM sources. This layer only
# merges sources and runs `mpm install`; it is independent of the FHS GUI
# wrappers in lib/fhs.nix and knows nothing about product selection.

{ pkgs }:

{ release,            # e.g. "R2026a"
  checksum,           # release checksum from product metadata
  closureProducts,    # metadata entries covering the dependency closure
  sources,            # fixed-output fetches, one per closureProducts entry
  selectedNames,      # top-level selected product names (what mpm installs)
}:
let
  lib = pkgs.lib;
  mpm = import ../modules/mpm.nix { inherit pkgs; };
  mergeMpmSources = import ./mergeMpmSources.nix { inherit pkgs; };

  src = mergeMpmSources {
    inherit release checksum;
    products = closureProducts;
    sources = sources;
  };
  prodArgs = lib.concatStringsSep " " selectedNames;
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "matlab";
  version = release;

  nativeBuildInputs = [ mpm.fhs ];

  src = src;
  dontUnpack = true;
  phases = [ "installPhase" ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    mpm-fhs -c "mpm install --source=\"$src\" --destination=$TEMPDIR/out --products=${prodArgs}"
    cp -r "$TEMPDIR/out" "$out"
    # Named-user activation creates this directory when its license is installed.
    mkdir -p "$out/out/licenses"
    runHook postInstall
  '';
}
