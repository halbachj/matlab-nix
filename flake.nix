{
  description = "mpm flake with dev-shell";

  inputs = {
    nixpkgs     .url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils .url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        mpm = import ./modules/mpm.nix { inherit pkgs; };
        mpmFetch = import ./lib/fetchMpm.nix { inherit pkgs mpm; };

        matlab = pkgs.stdenvNoCC.mkDerivation {
          pname = "matlab";
          version = "latest";

          src = mpmFetch {
            hash = "sha256-yAGlrkVOYjBSGv8arJd0KVR/4hdeQmlkY5hWfustRfI=";
              release     = "R2025a";
              products    = [
                "MATLAB"
                "Simulink"
              ];
          };
          dontUnpack = true;
          phases = [ "installPhase" ];
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
            cp -r "$src" "$out"
            runHook postInstall
          '';
        };

      in {
        packages.matlab = matlab;

        devShells.default = mpm.fhs.env ;
      });
}

