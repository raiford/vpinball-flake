# TODO: will segfault if ~/.config/user-dirs.dirs is not fully formed with xdg-user-dirs-update
{
  stdenv,
  pkgs,
  lib,
  inputs,
  vpinPkgs,
  buildType ? "Release"
}:
stdenv.mkDerivation {
  pname = "vpinball";
  # Version reflects the pinned upstream commit, e.g. "unstable-1a2b3c".
  version = "unstable-${lib.strings.substring 0 6 inputs.vpinball.rev}";

  src = inputs.vpinball;

  nativeBuildInputs = with pkgs; [
    pkg-config
    bison
    cmake
  ];

  buildInputs = (with pkgs; [
    # vpinball upstream is using a SHA that is pinned around v7
    # If the vpinball updates to v8 this should be updated.
    ffmpeg

    # System dependencies
    libzip
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
  ])
  # SHA-pinned custom dependencies (see vpinPkgs in flake.nix)
  ++ (with vpinPkgs; [
    freeimage
    bgfx
    bgfx-shaderc
    pinmame
    libdmdutil
    libwinevbs
    libaltsound
    libdof
    libpupdmd
    libserum
    hidapi
    libvni
    openxr
    zlib
    libogg
    libopus
    opusfile
    libmysofa
    libspatialaudio
    pinmame-data
    sdl3
    sdl3-ttf
    sdl3-image
  ]);

  hardeningDisable = [ "format" ];

  # Upstream's platforms/linux-x64/external.sh normally downloads and builds
  # these into the third-party/ staging tree. In Nix each is a separate
  # derivation; stage them into the (writable) workspace to mirror that layout.
  # Note: $PWD, not $src — the store path is read-only.
  preConfigure = ''
    runHook prePreConfigure

    # shaderc host tool (compiles the embedded BGFX shaders at build time)
    mkdir -p third-party/tools/linux-x64
    cp ${vpinPkgs.bgfx-shaderc}/bin/shaderc third-party/tools/linux-x64/

    # Static libs linked by name from third-party/build-libs/linux-x64
    mkdir -p third-party/build-libs/linux-x64
    cp ${vpinPkgs.zlib}/lib/libz.a third-party/build-libs/linux-x64/
    cp ${vpinPkgs.libogg}/lib/libogg.a third-party/build-libs/linux-x64/
    cp ${vpinPkgs.libopus}/lib/libopus.a third-party/build-libs/linux-x64/
    cp ${vpinPkgs.opusfile}/lib/libopusfile.a third-party/build-libs/linux-x64/
    cp ${vpinPkgs.libmysofa}/lib/libmysofa.a third-party/build-libs/linux-x64/
    cp ${vpinPkgs.libspatialaudio}/lib/libspatialaudio.a third-party/build-libs/linux-x64/

    # OpenXR runtime loader (linked from third-party/runtime-libs/linux-x64)
    mkdir -p third-party/runtime-libs/linux-x64
    cp -a ${vpinPkgs.openxr}/lib/libopenxr_loader.so* third-party/runtime-libs/linux-x64/

    # Headers expected under third-party/include/
    cp -r ${vpinPkgs.zlib}/include/. third-party/include/
    cp -r ${vpinPkgs.libogg}/include/ogg third-party/include/
    # The pinned opus/opusfile installs under include/opus/; upstream
    # flattens these into third-party/include/ (miniaudio includes <opusfile.h>)
    cp ${vpinPkgs.libopus}/include/opus/*.h third-party/include/
    cp ${vpinPkgs.opusfile}/include/opus/opusfile.h third-party/include/
    cp ${vpinPkgs.libmysofa}/include/mysofa.h ${vpinPkgs.libmysofa}/include/mysofa_export.h third-party/include/
    cp -r ${vpinPkgs.libspatialaudio}/include/spatialaudio third-party/include/
    mkdir -p third-party/include/openxr
    cp ${vpinPkgs.openxr}/include/openxr/*.h third-party/include/openxr/

    # PinMAME machine data, shipped with the pinmame plugin as default data
    mkdir -p third-party/memmaps third-party/gamedefs
    cp -r ${vpinPkgs.pinmame-data}/memmaps/. third-party/memmaps/
    cp -r ${vpinPkgs.pinmame-data}/gamedefs/. third-party/gamedefs/

    runHook postPreConfigure
  '';

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
