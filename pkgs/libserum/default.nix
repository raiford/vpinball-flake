{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libserum";

  src = inputs.libserum;

  nativeBuildInputs = with pkgs; [
    cmake
    libframeutil
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DBUILD_SHARED=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Library for decoding Serum DMD colorization files (concentrate fork)";
    homepage = "https://github.com/ppuc/libserum_concentrate";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };
}
