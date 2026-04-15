{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libdof";

  src = inputs.libdof;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    hidapi
    libserialport
    libftdi
    libusb
    systemd # for libudev
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Cross-platform C++ port of DirectOutput Framework for pinball feedback hardware";
    homepage = "https://github.com/jsm174/libdof";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
