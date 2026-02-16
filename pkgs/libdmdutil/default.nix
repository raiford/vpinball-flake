{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libdmdutil";

  src = inputs.libdmdutil;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    zlib
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
