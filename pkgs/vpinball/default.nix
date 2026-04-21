# TODO: will segfault if ~/.config/user-dirs.dirs is not fully formed with xdg-user-dirs-update
{
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release"
}:
stdenv.mkDerivation {
  pname = "vpinball";
  # TODO: what should the version be based on?  10.8.X?
  version = "unstable";

  src = inputs.vpinball;

  nativeBuildInputs = with pkgs; [
    pkg-config
    bison
    cmake
  ];

  buildInputs = with pkgs; [
    # Custom dependencies
    freeimage
    bgfx
    pinmame
    libdmdutil
    libwinevbs
    libaltsound
    libdof
    libpupdmd
    libserum
    libzip
    hidapi
    libvni

    # vpinball upstream is using a SHA that is pinned around v7
    # If the vpinball updates to v8 this should be updated.
    ffmpeg_7

    # System dependencies
    sdl3
    sdl3-ttf
    sdl3-image
    pipewire
    nasm
    libdrm
    libxi
    libgbm
    libGLU
    libGL
    egl-wayland
    libx11
    libxcursor
    libxscrnsaver
    libxrandr
    libxkbcommon
    libxtst
  ];

  # TODO separate targets for bgfx and gl
  postPatch = ''
    cp make/CMakeLists_bgfx-linux-x64.txt CMakeLists.txt

    # Fix Wayland/labwc freezes for secondary windows (like Score View / DMD) by removing the UTILITY and ALWAYS_ON_TOP flags
    # which causes them to be treated as unparented popups that get starved of frame callbacks at startup.
    sed -i 's/wnd_flags |= SDL_WINDOW_UTILITY | SDL_WINDOW_ALWAYS_ON_TOP;//' src/renderer/Window.cpp

    # Remove SDL_WINDOW_HIDDEN to ensure the Wayland surface is mapped and receives a configure event 
    # before BGFX attempts to create the swapchain, which otherwise results in a permanent 0x0 frozen window.
    sed -i 's/ | SDL_WINDOW_HIDDEN//' src/renderer/Window.cpp
  '';

  hardeningDisable = [ "format" ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_SHARED=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_CXX_FLAGS=-mssse3"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mkdir -p $out/plugins

    cp VPinballX_* $out/
    cp -r assets $out/
    cp -r scripts $out/
    cp -r docs $out/

    cp -r plugins $out/

    ln -s $out/VPinballX_* $out/bin/VPinballX

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Visual Pinball Engine (open-source pinball simulator)";
    homepage = "https://github.com/vpinball/vpinball";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = "VPinballX";
  };
}
