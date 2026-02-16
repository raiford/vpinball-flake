{
  stdenv,
  pkgs,
  inputs,
  sdl3,
}:
stdenv.mkDerivation {
  name = "sdl3-image";

  src = inputs.sdl3-image;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = [
    sdl3
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DSDLIMAGE_SAMPLES=OFF"
    "-DSDLIMAGE_DEPS_SHARED=ON"
    "-DSDLIMAGE_VENDORED=ON"
    "-DSDLIMAGE_AVIF=OFF"
    "-DSDLIMAGE_WEBP=OFF"
    "-DSDL3_DIR=${sdl3}"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
