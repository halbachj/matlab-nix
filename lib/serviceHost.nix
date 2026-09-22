# MathWorks Service Host: a separate, independently versioned download. It is a
# prerequisite for MATLAB Connector and other MathWorks service-host features and
# is packaged on its own so it can be enabled independently of the MATLAB core.

{ pkgs }:

let
  shrelease = "2025.3.0.2";
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "Matlab ServiceHost";
  version = shrelease;

  nativeBuildInputs = [ pkgs.coreutils pkgs.patchelf ];

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

  buildPhase = "true";
  checkPhase = "true";
}
