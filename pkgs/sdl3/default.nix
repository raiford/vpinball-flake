{
  stdenv,
  pkgs,
  inputs,
  ...
}:
stdenv.mkDerivation {
  name = "sdl3";

  src = inputs.sdl3;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    xorg.libX11
  ];

  cmakeFlags = [
    "-DSDL_SHARED=ON"
    "-DSDL_STATIC=OFF"
    "-DSDL_TEST_LIBRARY=OFF"
    "-DSDL_OPENGLES=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
