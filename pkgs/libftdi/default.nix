{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libftdi";

  src = inputs.libftdi;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    libusb
  ];

  preConfigure = ''
    sed -i.bak 's/cmake_minimum_required([^)]*)/cmake_minimum_required(VERSION 3.10)/' CMakeLists.txt
  '';

  cmakeFlags = [
    "-DFTDI_EEPROM=OFF"
    "-DEXAMPLES=OFF"
    "-DSTATICLIBS=OFF"
    "-DLIBUSB_INCLUDE_DIR=${pkgs.libusb}/include/libusb-1.0"
    "-DLIBUSB_LIBRARIES=${pkgs.libusb}/lib/libusb-1.0.so"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Library to talk to FTDI chips (jsm174 fork used by libdof)";
    homepage = "https://github.com/jsm174/libftdi";
    license = licenses.lgpl21;
    platforms = platforms.linux;
  };

}
