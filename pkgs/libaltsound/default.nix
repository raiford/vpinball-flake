{
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libaltsound";

  src = inputs.libaltsound;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  #buildInputs = with pkgs; [
  #  zlib
  #];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
