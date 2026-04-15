{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libpupdmd";

  src = inputs.libpupdmd;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DBUILD_SHARED=ON"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Library for detecting PUP (Pinup Player) DMD triggers for pinball emulation";
    homepage = "https://github.com/ppuc/libpupdmd";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
