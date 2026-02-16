{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libusb";

  src = inputs.libusb;

  nativeBuildInputs = with pkgs; [
    pkg-config
    autoconf
    automake
    libtool
  ];

  buildInputs = with pkgs; [
    systemd # for libudev
  ];

  preConfigure = "./autogen.sh";

  #installPhase = ''
  #  runHook preInstall

  #  mkdir -p $out/lib
  #  cp libserialport.{so,so.*} $out/lib
  #  cp libserialport.{so,so.*} $out/lib

  #  runHook postInstall
  #'';

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
