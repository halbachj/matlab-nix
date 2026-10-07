# pkgs/mpm.nix
{ pkgs }:

let
  mpm = pkgs.stdenvNoCC.mkDerivation {
    pname    = "mpm";
    version  = "latest";
    src = pkgs.fetchurl {
      url    = "https://www.mathworks.com/mpm/glnxa64/mpm";
      sha256 = "sha256-dZUwn8LDmp3ZboOMY48EHDPOyxHd/tF7v3EnCfmf0qU=";
    };

    dontUnpack = true;

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = with pkgs; [
      glibc          # loader
      zlib
      stdenv.cc.cc   # libstdc++.so.6
    ];

    installPhase = ''
      install -Dm755 $src $out/bin/mpm
    '';

    meta.platforms = [ "x86_64-linux" ];
  };

  matlabLibs = with pkgs; [
    unzip pam zlib libGL mesa gtk3 pango cairo freetype fontconfig
    # ncurses ABI-5 compatibility (libtinfo.so.5). nixpkgs exposes this as
    # `ncurses5`; some nixpkgs revisions or overlays name it `ncurses5Compat`.
    (pkgs.ncurses5Compat or pkgs.ncurses5)
    stdenv.cc.cc.lib
  ];

  mpmFHS = pkgs.buildFHSEnv {
    name       = "mpm-fhs";
    targetPkgs = _: matlabLibs ++ [ mpm ];
    runScript  = "bash";        # So we can just call `mpm-fhs …`
  };

in
{
  mpm = mpm;
  fhs = mpmFHS;
}
