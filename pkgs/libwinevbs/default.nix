{
  lib,
  stdenv,
  pkgs,
  inputs,
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
    "-DBUILD_STATIC=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
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
