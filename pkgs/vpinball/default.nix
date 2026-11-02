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
    bgfx-shaderc
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
    openxr
    zlibStatic
    liboggStatic
    libopusStatic
    opusfileStatic
    libmysofaStatic
    libspatialaudioStatic
    pinmame-data

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

  hardeningDisable = [ "format" ];

  # Upstream's platforms/linux-x64/external.sh normally downloads and builds
  # these into the third-party/ staging tree. In Nix each is a separate
  # derivation; stage them into the (writable) workspace to mirror that layout.
  # Note: $PWD, not $src — the store path is read-only.
  preConfigure = ''
    runHook prePreConfigure

    # shaderc host tool (compiles the embedded BGFX shaders at build time)
    mkdir -p third-party/tools/linux-x64
    cp ${pkgs.bgfx-shaderc}/bin/shaderc third-party/tools/linux-x64/

    # Static libs linked by name from third-party/build-libs/linux-x64
    mkdir -p third-party/build-libs/linux-x64
    cp ${pkgs.zlibStatic}/lib/libz.a third-party/build-libs/linux-x64/
    cp ${pkgs.liboggStatic}/lib/libogg.a third-party/build-libs/linux-x64/
    cp ${pkgs.libopusStatic}/lib/libopus.a third-party/build-libs/linux-x64/
    cp ${pkgs.opusfileStatic}/lib/libopusfile.a third-party/build-libs/linux-x64/
    cp ${pkgs.libmysofaStatic}/lib/libmysofa.a third-party/build-libs/linux-x64/
    cp ${pkgs.libspatialaudioStatic}/lib/libspatialaudio.a third-party/build-libs/linux-x64/

    # OpenXR runtime loader (linked from third-party/runtime-libs/linux-x64)
    mkdir -p third-party/runtime-libs/linux-x64
    cp -a ${pkgs.openxr}/lib/libopenxr_loader.so* third-party/runtime-libs/linux-x64/

    # Headers expected under third-party/include/
    cp -r ${pkgs.zlibStatic}/include/. third-party/include/
    cp -r ${pkgs.liboggStatic}/include/ogg third-party/include/
    # The pinned opus/opusfile installs under include/opus/; upstream
    # flattens these into third-party/include/ (miniaudio includes <opusfile.h>)
    cp ${pkgs.libopusStatic}/include/opus/*.h third-party/include/
    cp ${pkgs.opusfileStatic}/include/opus/opusfile.h third-party/include/
    cp ${pkgs.libmysofaStatic}/include/mysofa.h ${pkgs.libmysofaStatic}/include/mysofa_export.h third-party/include/
    cp -r ${pkgs.libspatialaudioStatic}/include/spatialaudio third-party/include/
    mkdir -p third-party/include/openxr
    cp ${pkgs.openxr}/include/openxr/*.h third-party/include/openxr/

    # PinMAME machine data, shipped with the pinmame plugin as default data
    mkdir -p third-party/memmaps third-party/gamedefs
    cp -r ${pkgs.pinmame-data}/memmaps/. third-party/memmaps/
    cp -r ${pkgs.pinmame-data}/gamedefs/. third-party/gamedefs/

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
