# Build test for a small known product set (MATLAB only). This actually downloads
# and installs MATLAB via MPM, so it requires network access and the real pinned
# hashes from lib/products.nix. It is intentionally NOT part of `checks` /
# `nix flake check` so CI never publishes MATLAB outputs; run it manually:
#
#   nix build .#checks.matlabBuild   (if wired)  or:
#   nix build .#matlabRaw

{ pkgs, lib }:

let
  cfg = lib.evalModules {
    modules = [
      (import ../modules/matlab.nix)
      {
        programs.matlab = {
          release = "R2026a";
          installedProducts = [ "matlab" ];
        };
      }
    ];
  } .config.programs.matlab;

  fetchMpm = import ../lib/fetchMpm.nix {
    inherit pkgs;
    mpm = import ../modules/mpm.nix { inherit pkgs; };
  };
  installMatlab = import ../lib/install.nix { inherit pkgs; };

  release = cfg.release;
  mpmSources = map (product: fetchMpm {
    inherit release;
    hash = product.hash;
    product = product.name;
  }) cfg.closureProducts;
in
installMatlab {
  inherit release;
  checksum = cfg.releaseMetadata.checksum;
  closureProducts = cfg.closureProducts;
  sources = mpmSources;
  selectedNames = map (p: p.name) cfg.selectedProducts;
}
