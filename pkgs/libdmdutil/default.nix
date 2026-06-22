{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libdmdutil";

  src = inputs.libdmdutil;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    zlib
    libframeutil
    libzedmd
    libserum
    libpupdmd
    libserialport
    sockpp
    cargs
    libusb
    libvni
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Cross-platform library for performing DMD tasks used by vpinball";
    homepage = "https://github.com/vpinball/libdmdutil";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };

}
