{
  lib,
  stdenv,
  pkgs,
  fetchFromGitHub,
  bgfx-cmake,
  bgfx-patch,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "bgfx";
  # TODO: figure out a better way to parameterize the version of the separate packages.
  #version = "1.29.8940-496";

  # Pull the cmake src and copy the patched bgfx version into it later.
  srcs = [
    (builtins.path {path =bgfx-patch.outPath; name = "bgfx-patch";})
    (builtins.path {path =bgfx-cmake.outPath; name = "bgfx.cmake";})
  ] ;

  sourceRoot = "bgfx.cmake";

  # move the patched bgfx into the cmake src
  postUnpack = ''
    rm -rf bgfx.cmake/bgfx
    cp -rf bgfx-patch bgfx.cmake/bgfx
  '';

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    libX11
    libxcb
    libGLU
    wayland
    libglvnd
  ];

  cmakeFlags = [
    "-DBGFX_LIBRARY_TYPE=SHARED"
    "-DBGFX_BUILD_TOOLS=OFF"
    "-DBGFX_BUILD_EXAMPLES=OFF"
    "-DBGFX_CONFIG_MULTITHREADED=ON"
    "-DBGFX_CONFIG_MAX_FRAME_BUFFERS=256"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    mkdir -p $out/include

    cp -a cmake/bgfx/libbgfx.so $out/lib
    cp cmake/bimg/libbimg_encode.a $out/lib

    cp -r ../bgfx/include/bgfx $out/include
    cp -r ../bimg/include/bimg $out/include
    cp -r ../bx/include/bx $out/include

    runHook postInstall
  '';


  meta = with lib; {
    description = "Cross-platform rendering library (bgfx.cmake build with vpinball's patched bgfx)";
    homepage = "https://github.com/bkaradzic/bgfx.cmake";
    license = licenses.bsd2;
    platforms = platforms.linux;
  };
}
