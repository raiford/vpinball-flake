{
  stdenv,
  pkgs,
  fetchFromGitHub,
  bgfx-cmake,
  bgfx-patch,
}:
stdenv.mkDerivation {
  name = "bgfx";
  # TODO: figure out a better way to parameterize the version of the separate packages.
  #version = "1.29.8940-496";

  # Pull the cmake src and copy the patched bgfx version into it later.
  srcs = [
    #(fetchFromGitHub {
    #  owner = bgfx-cmake.owner;
    #  repo = bgfx-cmake.repo;
    #  rev = bgfx-cmake.rev;
    #  hash = bgfx-cmake.hash;
    #})
    #(fetchFromGitHub {
    #  owner = bgfx-patch.owner;
    #  repo = bgfx-patch.repo;
    #  rev = bgfx-patch.rev;
    #  hash = bgfx-patch.hash;
    #})
    #(bgfx-cmake // {name = "bgfx-cmake";})
    #(bgfx-patch // {name = "bgfx-patch";})
    #({
    #  name = "bgfx-cmake";
    #  src = bgfx-cmake.outPath;
    #})
    #({
    #  name = "bgfx-patch";
    #  src = bgfx-patch.outPath;
    #})
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
    xorg.libX11
    xorg.libxcb
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
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
