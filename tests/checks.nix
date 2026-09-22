# Evaluation tests for product selection and closure resolution. These are
# assertions that run during evaluation, so `nix flake check` catches a regression
# without building or downloading any MATLAB artifact.

{ pkgs, lib, matlabProducts, productMetadata }:

let
  # Evaluate `programs.matlab` for a given product selection against R2026a.
  evalFor = installedProducts: lib.evalModules {
    modules = [
      (import ../modules/matlab.nix)
      {
        programs.matlab = {
          release = "R2026a";
          installedProducts = installedProducts;
        };
      }
    ];
    specialArgs = { inherit matlabProducts productMetadata; };
  };

  names = cfg: map (p: p.name) cfg.closureProducts;

  # Assert that the resolved dependency closure matches `expected` (in any order).
  expectClosure = installedProducts: expected:
    let
      cfg = (evalFor installedProducts).config.programs.matlab;
      got = names cfg;
      sorted = a: lib.sort (x: y: x < y) a;
    in
    assert sorted got == sorted expected; got;

  # A check must reference its asserted value so evaluation forces the assert.
  mkCheck = name: value:
    pkgs.runCommand "check-${name}" { } ''
      echo "ok: ${toString value}" > $out
    '';
in
{
  # Closure of [ matlab simulink imageProcessing ] is MATLAB (shared dependency
  # of Simulink and Image Processing), Simulink, and Image Processing.
  closure = mkCheck "closure"
    (expectClosure [ "matlab" "simulink" "imageProcessing" ]
      [ "MATLAB" "Simulink" "Image_Processing_Toolbox" ]);

  # MATLAB alone has an empty dependency closure.
  matlabOnly = mkCheck "matlab-only"
    (expectClosure [ "matlab" ] [ "MATLAB" ]);

  # Signal Processing is an independent dependency of MATLAB, so adding it to a
  # MATLAB + Simulink selection keeps the closure flat.
  toolboxes = mkCheck "toolboxes"
    (expectClosure [ "matlab" "simulink" "signalProcessing" ]
      [ "MATLAB" "Simulink" "Signal_Processing_Toolbox" ]);
}
