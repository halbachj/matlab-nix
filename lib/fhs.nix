# FHS GUI wrappers for running the raw MATLAB install tree. This layer is purely
# about launching MATLAB, the MathWorks Service Host, and MATLAB Connector under
# buildFHSEnv; it contains no product-selection, download, or install logic.

{ pkgs, matlabLibs }:

{ matlabRaw,       # raw install tree from lib/install.nix
  serviceHost,     # raw Service Host tree from lib/serviceHost.nix
  shrelease,       # Service Host release, e.g. "2025.3.0.2"
  enableConnector ? false,   # connector is experimental; build only if enabled
}:
let
  matlabFHS = pkgs.buildFHSEnv {
    name = "matlab-fhs";
    extraMounts = [
      "/home:/home"                              # preserve user environment
      "/tmp:/tmp"                                # required for MATLAB IPC
      "/etc/resolv.conf:/etc/resolv.conf:ro"     # license server DNS resolution
      "/etc/localtime:/etc/localtime:ro"         # timezone consistency
      "/dev:/dev"                                # device access
      "/dev/shm:/dev/shm"                        # shared memory (critical for MVM)
      "/proc:/proc"                              # some MATLAB subsystems rely on procfs
      "/sys:/sys"                                # sometimes required by MATLAB runtime
    ];

    targetPkgs = pkgs: matlabLibs ++ [ pkgs.coreutils matlabRaw pkgs.tree pkgs.libsForQt5.full ];

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
    name = "service-host-fhs";
    targetPkgs = pkgs: matlabLibs ++ [ pkgs.coreutils serviceHost pkgs.tree pkgs.libsForQt5.full pkgs.boost ];
    runScript = ''
      #!/bin/sh
      export LD_LIBRARY_PATH=/lib:/usr/lib:$LD_LIBRARY_PATH
      exec ${serviceHost}/v${shrelease}/bin/glnxa64/MathWorksServiceHost "$@"
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
in
{
  matlab = matlabFHS;
  serviceHost = shFHS;
  serviceHostWindow = serviceHostWindowFHS;
  connector = connectorFHS;   # experimental; exposed only when enableConnector
}
