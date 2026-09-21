{
  description = "mpm flake with dev-shell";

  inputs = {
    nixpkgs     .url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils .url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    {
      nixosModules.matlab = import ./modules/matlab.nix;
    }
    // flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        lib = nixpkgs.lib;
        matlabLibs = import ./lib/common.nix { inherit pkgs; };
        matlabConfig = lib.evalModules {
          modules = [
            ./modules/matlab.nix
            {
              matlab = {
                release = "R2026a";
                products = [
                  "MATLAB"
                  "Simulink"
                  "Image_Processing_Toolbox"
                  "Signal_Processing_Toolbox"
                ];
              };
            }
          ];
        };
        inherit (matlabConfig.config.matlab) release products;
        prodArgs = lib.concatStringsSep " " products;

        mpm = import ./modules/mpm.nix { inherit pkgs; };
        mpmFetch = import ./lib/fetchMpm.nix { inherit pkgs mpm; };

        shrelease = "2025.3.0.2";
        matlabServiceHost = pkgs.stdenvNoCC.mkDerivation {
          pname = "Matlab ServiceHost";
          version = shrelease;

          nativeBuildInputs = matlabLibs ++ [ pkgs.coreutils pkgs.patchelf ];

          src = pkgs.fetchzip {
            url = "https://ssd.mathworks.com/supportfiles/downloads/MathWorksServiceHost/v${shrelease}/release/glnxa64/managed_mathworksservicehost_${shrelease}_package_glnxa64.zip";
            hash = "sha256-L92Ly4TYxX5FX/d940uSPM8DXK31LC4rw9uixllMIY0=";
            stripRoot = false;
          };

          # patchPhase runs in the unpacked build directory (writeable)
          patchPhase = ''
            echo "Setting \$ORIGIN RPATH on all glnxa64 binaries…"
            for exe in v${shrelease}/bin/glnxa64/*; do
              patchelf --set-rpath '\$ORIGIN' "$exe"
            done
          '';

          # install only copies the now-patched files into $out
          installPhase = ''
            mkdir -p $out/v${shrelease}
            cp -r $src/* $out/v${shrelease}

            mkdir -p $out
            cat > $out/LatestInstall.info <<EOF
            LatestDSInstallerVersion ${shrelease}
            LatestDSInstallRoot    $out/v${shrelease}
            DSLauncherExecutable   $out/v${shrelease}/bin/glnxa64/MathWorksServiceHost
            EOF

          '';

          # we’re not building anything else
          buildPhase = "true";
          checkPhase = "true";


        };
        matlabRaw = pkgs.stdenvNoCC.mkDerivation {
          pname = "matlab";
          version = "latest";

          nativeBuildInputs = [ mpm.fhs ];
          
          src = mpmFetch {
             hash = "sha256-EF2qws3SOEjOlYk1ENk+5rhHKPJtX9DFmbVQszuNfkg=";
             inherit release products;
          };
          dontUnpack = true;
          phases = [ "installPhase" ];          
          installPhase = ''
            runHook preInstall
            mkdir -p "$out"
             mpm-fhs -c "mpm install --source="$src" --destination=$TEMPDIR/out --products=${prodArgs}"
             cp -r "$TEMPDIR/out" "$out"
             # R2026a creates this directory when named-user activation installs its license.
             mkdir -p "$out/out/licenses"
             runHook postInstall
          '';
          #postInstall = ''
          #  # Clear executable-stack on Service Host libs
          #  patchelf --clear-execstack \
          #    "$out/.MathWorks/ServiceHost/-mw_shared_installs/v2025.2.2.1/mci/bin/glnxa64/libmwfoundation_crash_handling.so"
          #  patchelf --clear-execstack \
          #    "$out/.MathWorks/ServiceHost/-mw_shared_installs/v2025.2.2.1/mci/bin/glnxa64/mathworksservicehost/rcf/matlabconnector/serviceprocess/rcf/service/libmwmshrcfservice.so"
          #'';
        };
        matlabFHS = pkgs.buildFHSEnv {
          name       = "matlab-fhs";
          extraMounts = [
            "/home:/home"                                 # preserve user environment
            "/tmp:/tmp"                                   # required for MATLAB IPC
            "/etc/resolv.conf:/etc/resolv.conf:ro"        # license server DNS resolution
            "/etc/localtime:/etc/localtime:ro"            # timezone consistency

            "/dev:/dev"                                   # device access (e.g., /dev/urandom, /dev/null)
            "/dev/shm:/dev/shm"                           # shared memory (critical for MVM)
            "/proc:/proc"                                 # some MATLAB subsystems may rely on procfs
            "/sys:/sys"                                   # sometimes required by MATLAB runtime
          ];

          targetPkgs = pkgs: matlabLibs ++ [ pkgs.coreutils matlabRaw pkgs.tree pkgs.libsForQt5.full ];
          # R2025a updates this file during startup even though the installation is immutable.
          extraPreBwrapCmds = ''
            matlab_settings_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/matlab-nix/toolbox-local-settings"
            matlab_license_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/matlab-nix/licenses"
            ${pkgs.coreutils}/bin/mkdir -p "$matlab_settings_dir"
            ${pkgs.coreutils}/bin/mkdir -p "$matlab_license_dir"
            if [ ! -e "$matlab_settings_dir/ddux.mlsettings" ]; then
              ${pkgs.coreutils}/bin/cp ${matlabRaw}/out/toolbox/local/settings/ddux.mlsettings "$matlab_settings_dir/"
              ${pkgs.coreutils}/bin/chmod u+w "$matlab_settings_dir/ddux.mlsettings"
            fi
          '';
          extraBwrapArgs = [
            "--bind \"$matlab_settings_dir\" ${matlabRaw}/out/toolbox/local/settings"
            "--bind \"$matlab_license_dir\" ${matlabRaw}/out/licenses"
          ];
          runScript = ''
            #!/bin/sh
            export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib64/qt-5.15.17/plugins/platforms
            export QT_QPA_PLATFORM=xcb
            export LDPATH_SUFFIX=${pkgs.xorg.libICE}/lib:${pkgs.xorg.xcbutilcursor}/lib:/usr/lib:/usr/lib64
            exec ${matlabRaw}/out/bin/matlab "$@"
          '';
        };
        shFHS = pkgs.buildFHSEnv {
          name       = "service-host-fhs";
          targetPkgs = pkgs: matlabLibs ++ [ pkgs.coreutils matlabServiceHost pkgs.tree pkgs.libsForQt5.full pkgs.boost ];
          #multiPkgs = true;              # allow multiple packages
          runScript = ''
            #!/bin/sh
            export LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH
            exec ${matlabServiceHost}/v${shrelease}/bin/glnxa64/MathWorksServiceHost "$@"
          '';
        };
        serviceHostWindowFHS = pkgs.buildFHSEnv {
          name = "service-host-window-fhs";
          targetPkgs = pkgs: matlabLibs ++ [ pkgs.coreutils pkgs.libsForQt5.full ];
          runScript = ''
            #!/bin/sh
            export QT_QPA_PLATFORM=xcb
            export LD_LIBRARY_PATH=${pkgs.xorg.libICE}/lib:${pkgs.xorg.xcbutilcursor}/lib:/usr/lib:/usr/lib64
            for window in "$HOME"/.MathWorks/ServiceHost/-mw_shared_installs/*/bin/glnxa64/MathWorksServiceHostWindow; do
              if [ -x "$window" ]; then
                exec "$window" "$@"
              fi
            done
            echo "MathWorksServiceHostWindow is not installed" >&2
            exit 1
          '';
        };
        connectorFHS = pkgs.buildFHSEnv {
          name = "matlab-connector-fhs";
          targetPkgs = pkgs: matlabLibs ++ [ pkgs.coreutils pkgs.libsForQt5.full ];
          runScript = ''
            #!/bin/sh
            export QT_QPA_PLATFORM=xcb
            export LD_LIBRARY_PATH=${pkgs.xorg.libICE}/lib:${pkgs.xorg.xcbutilcursor}/lib:/usr/lib:/usr/lib64
            for connector in "$HOME"/.MathWorks/ServiceHost/feather/v*/bin/MATLABConnector "$HOME"/.MathWorks/ServiceHost/-mw_shared_installs/*/bin/MATLABConnector; do
              if [ -x "$connector" ]; then
                export LD_LIBRARY_PATH="$(dirname "$connector")/glnxa64:$LD_LIBRARY_PATH"
                if [ "$1" = "--window" ]; then
                  shift
                  exec "$(dirname "$connector")/glnxa64/MATLABConnectorWindow" "$@"
                fi
                if [ "$1" = "--agent" ]; then
                  shift
                  exec "$(dirname "$connector")/glnxa64/MATLABConnector" "$@"
                fi
                exec "$connector" "$@"
              fi
            done
            echo "MATLAB Connector is not installed" >&2
            exit 1
          '';
        };

      in {
        packages.matlab = matlabFHS;
        packages.matlabRaw = matlabRaw;
        packages.serviceHost = shFHS;
        packages.serviceHostWindow = serviceHostWindowFHS;
        packages.connector = connectorFHS;
        
        devShells.default = mpm.fhs.env ;
        devShells.matlab = matlabFHS;
        devShells.serviceHost = shFHS;
      });
}
