{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libwinevbs";

  src = inputs.libwinevbs;

  nativeBuildInputs = with pkgs; [
    bison
    cmake
  ];

  #buildInputs = with pkgs; [
  #];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=${buildType}"
    "-DCMAKE_C_FLAGS=-Wno-format-security"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/include/libwinevbs
    mkdir -p $out/lib

    cp -a libwinevbs.so* $out/lib
    cp -r ../include/* $out/include/libwinevbs/
    cp -r ../wine/include/* $out/include/
    cp -r ../atl/include/* $out/include/
    cp -r ../atlmfc/include/* $out/include/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Wine-based VBScript (Visual Basic Script) runtime wrapper used by vpinball";
    homepage = "https://github.com/vpinball/libwinevbs";
    # No LICENSE file in repo; README states code is from Wine (LGPL-2.1) and ReactOS (GPL-2.0)
    license = with licenses; [ lgpl21Only gpl2Only ];
    platforms = platforms.linux;
  };

}
