{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "hidapi";

  src = inputs.hidapi;

  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
  ];

  buildInputs = with pkgs; [
    systemd # for libudev
    libusb
  ];

  cmakeFlags = [
    "-DHIAPI_WITH_LIBUSB=OFF"
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
