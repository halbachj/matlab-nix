{ pkgs, mpm }:

{ hash,                          # required: content hash (sha256- prefix or base-32)
  release,                        # e.g. "R2025a"
  product,                        # e.g. "MATLAB"
  destination ? "$TMPDIR/out"    # shell-expanded
}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "mpm-fetch";
  version = "1"; # Not needed but makes hydra happy?

  # A fetcher *must* be a fixed-output derivation:
  outputHashAlgo = "sha256";
  outputHash     = hash;
  outputHashMode = "recursive";

  nativeBuildInputs = [ mpm.fhs ];

  dontUnpack = true;
  allowSubstitutes = false;     # network access, so never cached by Hydra

  buildPhase = ''
    echo ">> Downloading ${product} for ${release} with mpm …"
    mkdir -p ${destination}
    mpm-fhs -c "mpm download \
      --release ${release} \
      --destination ${destination} \
      --products ${product} \
      --no-deps"
  '';

  installPhase = ''
    cp -R ${destination}/. $out
  '';
}
