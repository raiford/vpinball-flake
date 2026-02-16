{
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libzedmd";

  src = inputs.libzedmd;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    libserialport # TODO: Attempting to use this from nixpkgs but might need to repackage.
    cargs
    libframeutil
    sockpp
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_SHARED=ON"
    "-DBUILD_STATIC=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
