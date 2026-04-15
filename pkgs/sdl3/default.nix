{
  lib,
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
    libX11
  ];

  cmakeFlags = [
    "-DSDL_SHARED=ON"
    "-DSDL_STATIC=OFF"
    "-DSDL_TEST_LIBRARY=OFF"
    "-DSDL_OPENGLES=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Simple DirectMedia Layer 3, a cross-platform development library for multimedia";
    homepage = "https://github.com/libsdl-org/SDL";
    license = licenses.zlib;
    platforms = platforms.linux;
  };
}
