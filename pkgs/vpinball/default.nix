# TODO: will segfault if ~/.config/user-dirs.dirs is not fully formed with xdg-user-dirs-update
{
  stdenv,
  pkgs,
  inputs,
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
    libaltsound
    libdof
    libpupdmd
    libserum
    ffmpeg
    libzip
    hidapi
    libvni

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
  '';

  #preConfigure = ''
  #  echo "before configure"
  #  pwd
  #  cat CMakeLists.txt
  #'';

  #postConfigure = ''
  #  echo "after configure"
  #  pwd
  #  ls -l
  #  ls CMakeFiles
  #  cat CMakeFiles/SerumPlugin.dir/build.make
  #'';

  hardeningDisable = [ "format" ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_SHARED=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_CXX_FLAGS=-mssse3"
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
    description = "Visual Pinball Engine";
    homepage = "https://github.com/vpinball/vpinball";
    license = licenses.unfree; # Please verify the license. # TODO: fix licenses
  };
}
