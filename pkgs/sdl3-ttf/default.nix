{
  stdenv,
  pkgs,
  sdl3,
  inputs,
}:
stdenv.mkDerivation {
  name = "sdl3-ttf";

  src = inputs.sdl3-ttf;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    sdl3
    harfbuzz #TODO: this is only used for iOS builds, make it conditional.
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DSDLTTF_SAMPLES=OFF"
    "-DSDLTTF_VENDORED=ON"
    "-DSDLTTF_HARFBUZZ=ON"
    "-DSDL3_DIR=${sdl3}"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
