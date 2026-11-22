# Tests for the MATLAB linker-environment helper. These run without MATLAB or
# an audio device: the launcher is extracted with a stubbed buildFHSEnv and a
# stub `matlab` records the environment it receives.

{ pkgs, lib }:

let
  execEnvironment = import ../lib/exec.nix { inherit pkgs; };
  helper = execEnvironment.helper;

  matlabStub = pkgs.writeShellScript "matlab-exec-test-stub" ''
    set -eu

    {
      if [ "''${MATLAB_NIX_ENV_CAPTURED-}" = 1 ]; then
        echo "captured=yes"
      else
        echo "captured=no"
      fi

      if [ "''${MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH+x}" = x ]; then
        echo "original_ld_set=yes"
        printf 'original_ld_value=%s\n' "$MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH"
      else
        echo "original_ld_set=no"
      fi

      if [ "''${MATLAB_NIX_ORIGINAL_LD_PRELOAD+x}" = x ]; then
        echo "original_preload_set=yes"
        printf 'original_preload_value=%s\n' "$MATLAB_NIX_ORIGINAL_LD_PRELOAD"
      else
        echo "original_preload_set=no"
      fi
    } > "$OUT/snapshot"

    "${helper}/bin/matlab-nix-exec" "${pkgs.coreutils}/bin/env" > "$OUT/child-env"
  '';

  matlabRaw = pkgs.runCommand "matlab-exec-test-install" { } ''
    mkdir -p "$out/out/bin"
    ln -s ${matlabStub} "$out/out/bin/matlab"
  '';

  fhsArgs = (import ../lib/fhs.nix {
    pkgs = pkgs // { buildFHSEnv = args: args; };
    matlabLibs = [ ];
  }) {
    inherit matlabRaw;
    serviceHost = matlabRaw;
    shrelease = "test";
  };

  launcher = pkgs.writeShellScript "matlab-exec-test-launcher" fhsArgs.matlab.runScript;

  # A minimal FHS is enough to prove buildFHSEnv installs the helper on PATH;
  # this only builds the FHS root, it does not execute bwrap.
  minimalFHS = pkgs.buildFHSEnv {
    name = "matlab-exec-test-fhs";
    targetPkgs = p: [ p.coreutils helper ];
    runScript = "true";
  };

  # Mirrors MATLAB's bundled libstdc++ problem: a program built against a newer
  # C++ runtime fails when an older libstdc++ is forced through LD_LIBRARY_PATH,
  # and succeeds when matlab-nix-exec restores the original (unset) environment.
  cxxRuntimeConflict = pkgs.stdenv.mkDerivation {
    name = "matlab-exec-library-conflict";
    nativeBuildInputs = [ pkgs.gcc15 ];
    dontUnpack = true;
    buildPhase = ''
      cat > main.cc <<'EOF'
      #include <format>
      #include <iostream>
      int main() { std::cout << std::format("{}", 42) << std::endl; }
      EOF
      g++ -std=c++20 main.cc -o $out
    '';
  };
in
{
  execUnset = pkgs.runCommand "check-exec-unset" { } ''
    mkdir -p "$out"
    OUT="$out" env -u LD_LIBRARY_PATH -u LD_PRELOAD ${launcher}

    grep -qx 'captured=yes' "$out/snapshot"
    grep -qx 'original_ld_set=no' "$out/snapshot"
    grep -qx 'original_preload_set=no' "$out/snapshot"
    ! grep -q '^LD_LIBRARY_PATH=' "$out/child-env"
    ! grep -q '^LD_PRELOAD=' "$out/child-env"

    touch "$out/passed"
  '';

  execEmpty = pkgs.runCommand "check-exec-empty" { } ''
    mkdir -p "$out"
    OUT="$out" LD_LIBRARY_PATH= LD_PRELOAD= ${launcher}

    grep -qx 'captured=yes' "$out/snapshot"
    grep -qx 'original_ld_set=yes' "$out/snapshot"
    grep -qx 'original_ld_value=' "$out/snapshot"
    grep -qx 'original_preload_set=yes' "$out/snapshot"
    grep -qx 'original_preload_value=' "$out/snapshot"
    grep -qx '^LD_LIBRARY_PATH=$' "$out/child-env"
    grep -qx '^LD_PRELOAD=$' "$out/child-env"

    touch "$out/passed"
  '';

  execPopulated = pkgs.runCommand "check-exec-populated" { } ''
    mkdir -p "$out"
    OUT="$out" LD_LIBRARY_PATH=/original/lib:/second LD_PRELOAD=/original/preload.so ${launcher}

    grep -qx 'captured=yes' "$out/snapshot"
    grep -qx 'original_ld_set=yes' "$out/snapshot"
    grep -qx 'original_ld_value=/original/lib:/second' "$out/snapshot"
    grep -qx 'original_preload_set=yes' "$out/snapshot"
    grep -qx 'original_preload_value=/original/preload.so' "$out/snapshot"
    grep -qx '^LD_LIBRARY_PATH=/original/lib:/second$' "$out/child-env"
    grep -qx '^LD_PRELOAD=/original/preload.so$' "$out/child-env"

    touch "$out/passed"
  '';

  execArguments = pkgs.runCommand "check-exec-arguments" { } ''
    ${helper}/bin/matlab-nix-exec ${pkgs.bash}/bin/sh -c \
      'test "$1" = "hello world" && test "$2" = ""' _ "hello world" ""
    touch "$out"
  '';

  execExitStatus = pkgs.runCommand "check-exec-exit-status" { } ''
    set +e
    ${helper}/bin/matlab-nix-exec ${pkgs.bash}/bin/sh -c 'exit 42'
    status=$?
    set -e
    test "$status" = 42
    touch "$out"
  '';

  execNoArguments = pkgs.runCommand "check-exec-no-arguments" { } ''
    set +e
    ${helper}/bin/matlab-nix-exec >/dev/null 2>&1
    status=$?
    set -e
    test "$status" = 2
    touch "$out"
  '';

  execDoesNotModifyParent = pkgs.runCommand "check-exec-parent" { } ''
    (
      export LD_LIBRARY_PATH=/parent/value
      export MATLAB_NIX_ENV_CAPTURED=1
      unset MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH
      ${helper}/bin/matlab-nix-exec ${pkgs.coreutils}/bin/true
      test "$LD_LIBRARY_PATH" = /parent/value
    )
    touch "$out"
  '';

  execWithoutCapture = pkgs.runCommand "check-exec-without-capture" { } ''
    (
      export LD_LIBRARY_PATH=/unchanged
      unset MATLAB_NIX_ENV_CAPTURED
      ${helper}/bin/matlab-nix-exec ${pkgs.bash}/bin/sh -c \
        'test "$LD_LIBRARY_PATH" = /unchanged'
    )
    touch "$out"
  '';

  execResolvesLibraryConflict = pkgs.runCommand "check-exec-library-conflict" { } ''
    set +e
    LD_LIBRARY_PATH=${pkgs.gcc12.cc.lib}/lib ${cxxRuntimeConflict} >/dev/null 2>&1
    direct_status=$?
    set -e
    test "$direct_status" != 0

    env -u MATLAB_NIX_ORIGINAL_LD_LIBRARY_PATH \
      MATLAB_NIX_ENV_CAPTURED=1 \
      ${helper}/bin/matlab-nix-exec ${cxxRuntimeConflict} >/dev/null

    touch "$out"
  '';

  execHelperInTargetPkgs =
    assert lib.elem helper (fhsArgs.matlab.targetPkgs pkgs);
    pkgs.runCommand "check-exec-target-pkgs" { } ''touch "$out"'';

  execHelperInFHS = pkgs.runCommand "check-exec-in-fhs" { } ''
    test -x ${minimalFHS.fhsenv}/usr/bin/matlab-nix-exec
    touch "$out"
  '';
}