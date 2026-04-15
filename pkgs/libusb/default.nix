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
    description = "Cross-platform user-mode USB device access library";
    homepage = "https://github.com/libusb/libusb";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
  };

}
