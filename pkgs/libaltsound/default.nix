{
  lib,
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

  meta = with lib; {
    description = "Library for alternate sound playback in pinball emulators (used by vpinball)";
    homepage = "https://github.com/vpinball/libaltsound";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
