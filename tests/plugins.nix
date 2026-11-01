{ pkgs, lib }:
let
  source = pkgs.runCommand "matlab-plugin-fixture" { } ''
    mkdir -p "$out/src/private" "$out/other scripts"
    touch "$out/src/example.m" "$out/src/private/helper.m"
    touch "$out/other scripts/another.m"
  '';
  evalPlugins = plugins: (lib.evalModules {
    modules = [
      ../modules/matlab.nix
      { programs.matlab = { release = "R2026a"; inherit plugins; }; }
    ];
  }).config.programs.matlab.plugins;
  plugins = evalPlugins {
    example = { inherit source; paths = [ "src" "other scripts" ]; };
    local.source = ../lib;
  };
  environment = import ../lib/plugins.nix { inherit pkgs; } plugins;
  invalid = paths: !(builtins.tryEval (builtins.deepSeq
    (evalPlugins { example = { inherit source paths; }; }).example.paths true)).success;
  matlabStub = pkgs.writeShellScript "matlab-plugin-test" ''
    set -eu
    test "''${MATLABPATH-unset}" = "$EXPECTED_MATLABPATH"
    test "$#" = 2
    test "$1" = -batch
    test "$2" = "disp('hello world')"
    touch "$out"
  '';
  matlabRaw = pkgs.runCommand "matlab-plugin-test-install" { } ''
    mkdir -p "$out/out/bin"
    ln -s ${matlabStub} "$out/out/bin/matlab"
  '';
  # Extract the actual launcher without building the FHS or MATLAB installation.
  wrapperFor = plugins: (import ../lib/fhs.nix {
    pkgs = pkgs // { buildFHSEnv = args: args; };
    matlabLibs = [ ];
  } {
    inherit matlabRaw plugins;
    serviceHost = matlabRaw;
    shrelease = "test";
  }).matlab.runScript;
  launcher = pkgs.writeShellScript "matlab-plugin-launcher" (wrapperFor plugins);
  plainLauncher = pkgs.writeShellScript "matlab-plain-launcher" (wrapperFor { });
in
{
  pluginOptions =
    assert evalPlugins { } == { };
    assert plugins.local.paths == [ "." ];
    assert lib.all invalid [ [ ] [ "" ] [ "/src" ] [ "../src" ] [ "src/../test" ] [ "src:test" ] [ "src\ntest" ] ];
    pkgs.runCommand "check-plugin-options" { } ''touch "$out"'';

  pluginLauncher = pkgs.runCommand "check-plugin-launcher" { } ''
    test -f ${environment.package}/0/example.m
    test -f ${environment.package}/0/private/helper.m
    test -f ${environment.package}/1/another.m
    test -f ${environment.package}/2/fhs.nix
    export EXPECTED_MATLABPATH=${lib.escapeShellArg environment.searchPath}
    env -u MATLABPATH ${launcher} -batch "disp('hello world')"
    MATLABPATH= ${launcher} -batch "disp('hello world')"
    export EXPECTED_MATLABPATH=${lib.escapeShellArg environment.searchPath}:/existing/path
    MATLABPATH=/existing/path ${launcher} -batch "disp('hello world')"
    export EXPECTED_MATLABPATH=/existing/path
    MATLABPATH=/existing/path ${plainLauncher} -batch "disp('hello world')"
    export EXPECTED_MATLABPATH=unset
    env -u MATLABPATH ${plainLauncher} -batch "disp('hello world')"
  '';
}
