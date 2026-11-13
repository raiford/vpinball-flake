{
  lib,
  stdenv,
  pkgs,
  vpinPkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libftdi";

  src = inputs.libftdi;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with vpinPkgs; [
    # libftdi builds inside libdof's upstream tree, so it follows libdof's
    # libusb pin.
    libusbDof
  ];

  preConfigure = ''
    sed -i.bak 's/cmake_minimum_required([^)]*)/cmake_minimum_required(VERSION 3.10)/' CMakeLists.txt
  '';

  cmakeFlags = [
    "-DFTDI_EEPROM=OFF"
    "-DEXAMPLES=OFF"
    "-DSTATICLIBS=OFF"
    "-DLIBUSB_INCLUDE_DIR=${vpinPkgs.libusbDof}/include/libusb-1.0"
    "-DLIBUSB_LIBRARIES=${vpinPkgs.libusbDof}/lib/libusb-1.0.so"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Library to talk to FTDI chips (jsm174 fork used by libdof)";
    homepage = "https://github.com/jsm174/libftdi";
    license = licenses.lgpl21;
    platforms = platforms.linux;
  };

}
