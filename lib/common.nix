/* This list of dependencies is based on the official Mathworks dockerfile for
   R2020a, available at
     https://github.com/mathworks-ref-arch/container-images
*/

{ pkgs }:
let
  libsm = pkgs.libsm or pkgs.xorg.libSM;
  libx11 = pkgs.libx11 or pkgs.xorg.libX11;
  libxcb = pkgs.libxcb or pkgs.xorg.libxcb;
  libxcomposite = pkgs.libxcomposite or pkgs.xorg.libXcomposite;
  libxcursor = pkgs.libxcursor or pkgs.xorg.libXcursor;
  libxcbCursor = pkgs.libxcb-cursor or pkgs.xorg.xcbutilcursor;
  libxdamage = pkgs.libxdamage or pkgs.xorg.libXdamage;
  libxext = pkgs.libxext or pkgs.xorg.libXext;
  libxfixes = pkgs.libxfixes or pkgs.xorg.libXfixes;
  libxft = pkgs.libxft or pkgs.xorg.libXft;
  libice = pkgs.libice or pkgs.xorg.libICE;
  libxi = pkgs.libxi or pkgs.xorg.libXi;
  libxinerama = pkgs.libxinerama or pkgs.xorg.libXinerama;
  libxrandr = pkgs.libxrandr or pkgs.xorg.libXrandr;
  libxrender = pkgs.libxrender or pkgs.xorg.libXrender;
  libxt = pkgs.libxt or pkgs.xorg.libXt;
  libxtst = pkgs.libxtst or pkgs.xorg.libXtst;
  libxxf86vm = pkgs.libxxf86vm or pkgs.xorg.libXxf86vm;

  matlabLibs = with pkgs; [
    cacert
    alsa-lib # libasound2
    atk
    glib
    glibc
    cairo
    cups
    dbus
    fontconfig
    freetype
    gdk-pixbuf
    #gst-plugins-base
    # gstreamer
    gtk3
    nspr
    nss
    pam
    pango
    #python27 #TODO: figure out why?
    #python36
    # python3.10 was dropped from newer nixpkgs; fall back to 3.12
    (pkgs.python310 or pkgs.python312)
    libselinux
    libsndfile
    libuuid
    libglvnd
    libdrm
    libgbm
    libxkbcommon
    mesa
    glibcLocales
    procps
    unzip
    zlib

    gtk2

    gcc
    gfortran

    # nixos specific
    udev
    jre
    ncurses # Needed for CLI
  ] ++ [
    libsm
    libx11
    libxcb
    libxcomposite
    libxcursor
    libxcbCursor
    libxdamage
    libxext
    libxfixes
    libxft
    libice
    libxi
    libxinerama
    libxrandr
    libxrender
    libxt
    libxtst
    libxxf86vm
  ];
in
  matlabLibs
