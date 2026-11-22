# Environment preservation for commands launched from MATLAB. MathWorks'
# launcher prepends its bundled library directories to LD_LIBRARY_PATH; those
# directories ship an older libstdc++ than many host utilities expect. Capture
# the caller's linker environment before MATLAB starts so `matlab-nix-exec` can
# restore it for child processes without changing MATLAB's own runtime.

{ pkgs }:

let
  helper = pkgs.writeShellApplication {
    name = "matlab-nix-exec";
    text = ''
      if [ "$#" -eq 0 ]; then
        echo "usage: matlab-nix-exec <command> [arguments...]" >&2
        exit 2
      fi

      if [ "''${MATLAB_NIX_ENV_CAPTURED:-0}" = 1 ]; then
        if [ "''${MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH+x}" = x ]; then
          export LD_LIBRARY_PATH="$MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH"
        else
          unset LD_LIBRARY_PATH
        fi

        if [ "''${MATLAB_NIX_ORIGINAL_LD_PRELOAD+x}" = x ]; then
          export LD_PRELOAD="$MATLAB_NIX_ORIGINAL_LD_PRELOAD"
        else
          unset LD_PRELOAD
        fi
      fi

      exec "$@"
    '';
  };

  # Sourced by the MATLAB FHS launcher before MathWorks' launcher runs. A shell
  # variable is left unset when the caller did not set it, preserving the
  # difference between "unset" and "set to an empty string".
  captureEnv = ''
    if [ "''${LD_LIBRARY_PATH+x}" = x ]; then
      export MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    else
      unset MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH
    fi

    if [ "''${LD_PRELOAD+x}" = x ]; then
      export MATLAB_NIX_ORIGINAL_LD_PRELOAD="$LD_PRELOAD"
    else
      unset MATLAB_NIX_ORIGINAL_LD_PRELOAD
    fi

    export MATLAB_NIX_ENV_CAPTURED=1
  '';
in
{
  inherit helper captureEnv;
}
