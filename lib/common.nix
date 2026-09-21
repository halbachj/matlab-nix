/* This list of dependencies is based on the official Mathworks dockerfile for
   R2020a, available at
     https://github.com/mathworks-ref-arch/container-images
*/

{ pkgs }:
let
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
    python310
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
  ] ++ (with xorg; [
    libSM
    libX11
    libxcb
    libXcomposite
    libXcursor
    xcbutilcursor
    libXdamage
    libXext
    libXfixes
    libXft
    libICE
    libXi
    libXinerama
    libXrandr
    libXrender
    libXt
    libXtst
    libXxf86vm
  ]);
in
  matlabLibs
