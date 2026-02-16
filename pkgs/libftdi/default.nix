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
    description = "TODO";
    #homepage = "https://steamdb.info/app/896660/";
    #changelog = "https://store.steampowered.com/news/app/892970?updates=true";
    #sourceProvenance = with sourceTypes; [
    #  binaryBytecode
    #  binaryNativeCode
    #];
    #license = licenses.unfree;
    #maintainers = with maintainers; [ aidalgol ];
    #platforms = [ "x86_64-linux" ];
  };

}
