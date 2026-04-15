{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libserialport";

  src = inputs.libserialport;

  nativeBuildInputs = with pkgs; [
    pkg-config
    autoconf
    automake
    libtool
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
    description = "Minimal cross-platform shared library for accessing serial ports";
    homepage = "https://github.com/sigrokproject/libserialport";
    license = licenses.lgpl3Plus;
    platforms = platforms.linux;
  };

}
