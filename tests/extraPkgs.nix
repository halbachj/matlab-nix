# Tests for `programs.matlab.extraPkgs`: the option default, inclusion of the
# requested packages in the MATLAB FHS, and the GStreamer plugin search path.
# These run during evaluation only, so they do not build GStreamer or MATLAB.

{ pkgs, lib }:
let
  evalExtra = extraPkgs:
    (lib.evalModules {
      modules = [
        ../modules/matlab.nix
        { programs.matlab = { release = "R2026a"; inherit extraPkgs; }; }
      ];
    }).config.programs.matlab.extraPkgs;

  matlabRaw = pkgs.runCommand "matlab-extra-pkgs-test-install" { } ''
    mkdir -p "$out/out/bin"
    touch "$out/out/bin/matlab"
  '';

  # The GStreamer packages used in the documentation example.
  gstPkgs = [
    pkgs.gst_all_1.gstreamer
    pkgs.gst_all_1.gst-plugins-base
    pkgs.gst_all_1.gst-plugins-good
  ];

  # Extract the FHS arguments without building the FHS or MATLAB installation.
  fhsFor = extraPkgs: (import ../lib/fhs.nix {
    pkgs = pkgs // { buildFHSEnv = args: args; };
    matlabLibs = [ ];
  } {
    inherit matlabRaw extraPkgs;
    serviceHost = matlabRaw;
    shrelease = "test";
  }).matlab;

  withGst = fhsFor gstPkgs;
  plain = fhsFor [ ];
  gstPath = lib.makeSearchPath "lib/gstreamer-1.0" gstPkgs;

  # `builtins.match` (used by `lib.hasInfix`) rejects strings that carry store
  # path context, so compare the launcher text without it.
  stripContext = builtins.unsafeDiscardStringContext;
  hasInfix = infix: content:
    lib.hasInfix (stripContext infix) (stripContext content);
in
{
  # The option defaults to an empty list and rejects non-package values.
  extraPkgsOptions =
    assert evalExtra [ ] == [ ];
    assert !(builtins.tryEval
      (builtins.deepSeq (evalExtra [ "not-a-package" ]) true)).success;
    pkgs.runCommand "check-extra-pkgs-options" { } ''touch "$out"'';

  # Every requested package becomes a target package of the MATLAB FHS.
  extraPkgsInFHSTargets =
    assert lib.all (p: lib.elem p (withGst.targetPkgs pkgs)) gstPkgs;
    assert !builtins.elem pkgs.gst_all_1.gstreamer (plain.targetPkgs pkgs);
    pkgs.runCommand "check-extra-pkgs-targets" { } ''touch "$out"'';

  # GStreamer plugin directories are exposed only when extraPkgs is nonempty,
  # and an existing plugin path is preserved.
  extraPkgsGStreamerPath =
    assert hasInfix gstPath withGst.runScript;
    assert hasInfix "\${GST_PLUGIN_SYSTEM_PATH_1_0:+:\$GST_PLUGIN_SYSTEM_PATH_1_0}"
      withGst.runScript;
    assert !hasInfix "GST_PLUGIN_SYSTEM_PATH_1_0" plain.runScript;
    pkgs.runCommand "check-extra-pkgs-gstreamer-path" { } ''touch "$out"'';
}