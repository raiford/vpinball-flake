{
  lib,
  stdenv,
  pkgs,
  vpinPkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "sdl3-ttf";

  src = inputs.sdl3-ttf;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with vpinPkgs; [
    sdl3
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DSDLTTF_SAMPLES=OFF"
    "-DSDLTTF_VENDORED=ON"
    "-DSDLTTF_HARFBUZZ=ON"
    "-DSDL3_DIR=${vpinPkgs.sdl3}"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "SDL3 TrueType font rendering library";
    homepage = "https://github.com/libsdl-org/SDL_ttf";
    license = licenses.zlib;
    platforms = platforms.linux;
  };
}
