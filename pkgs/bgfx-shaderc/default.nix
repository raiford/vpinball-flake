{
  lib,
  stdenv,
  pkgs,
  bgfx-cmake,
  bgfx-patch,
}:
stdenv.mkDerivation {
  name = "bgfx-shaderc";

  # Host tool only: compiles vpinball's embedded BGFX shaders at build time.
  # Upstream always builds it in Release, independent of the app build type.
  srcs = [
    (builtins.path { path = bgfx-patch.outPath; name = "bgfx-patch"; })
    (builtins.path { path = bgfx-cmake.outPath; name = "bgfx.cmake"; })
  ];
  sourceRoot = "bgfx.cmake";

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
    "-DBGFX_BUILD_TOOLS=ON"
    "-DBGFX_BUILD_TOOLS_SHADER=ON"
    "-DBGFX_BUILD_TOOLS_BIN2C=OFF"
    "-DBGFX_BUILD_TOOLS_GEOMETRY=OFF"
    "-DBGFX_BUILD_TOOLS_TEXTURE=OFF"
    "-DBGFX_BUILD_EXAMPLES=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp cmake/bgfx/shaderc $out/bin/

    runHook postInstall
  '';

  meta = with lib; {
    description = "bgfx shader compiler host tool (shaderc) used by vpinball to compile embedded shaders";
    homepage = "https://github.com/bkaradzic/bgfx.cmake";
    license = licenses.bsd2;
    platforms = platforms.linux;
  };
}
