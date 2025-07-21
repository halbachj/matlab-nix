{ pkgs, mpm }:

{ hash,                          # required: content hash (sha256- prefix or base-32)
  outputHashMode ? "recursive",  # "recursive" for directories, "flat" if you know you'll get a single file
  inputFile   ? null,           # path to mpm input file (exclusive)
  release     ? null,           # e.g. "R2025a"
  products    ? [],             # e.g. [ "MATLAB" "Simulink" ]
  destination ? "$TMPDIR/out",  # shell-expanded
  noDeps      ? false           # omit dependencies
}:
let
  lib       = pkgs.lib;
  prodArgs  = lib.concatStringsSep " " products;
  noDepsArg = lib.optionalString noDeps " --no-deps";
in
  pkgs.stdenvNoCC.mkDerivation {
    pname = "mpm-fetch";
    version = "1"; # Not needed but makes hydra happy?

    # A fetcher *must* be a fixed-output derivation:
    outputHashAlgo = "sha256";
    outputHash     = hash;
    outputHashMode = outputHashMode;

    nativeBuildInputs = [ mpm.fhs ];

    dontUnpack = true;
    allowSubstitutes = false;     # network access, so never cached by Hydra

    #TODO: Allow for choosing packages and version in mpm
    buildPhase = ''
      echo ">> Downloading matlab with mpm …"
      mkdir -p ${destination}
      if [ -n "${inputFile}" ]; then
        mpm-fhs -c "mpm download --input-file ${inputFile}"
      else
        mpm-fhs -c "mpm download \
          --release ${release} \
          --destination ${destination} \
          --products ${prodArgs}${noDepsArg}"
      fi
    '';

    installPhase = ''
      cp -R ${destination}/. $out
    '';
}

