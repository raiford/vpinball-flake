{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libvni";

  src = inputs.libvni;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DBUILD_SHARED=ON"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    mkdir -p $out/include
    cp ../src/vni.h $out/include
    cp libvni.{so,so.*} $out/lib

    runHook postInstall
  '';

  meta = with lib; {
    description = "Library for handling Virtual Pinball Nine (VNI) colorization files for DMDs";
    homepage = "https://github.com/PPUC/libvni";
    license = licenses.gpl2Only;
    platforms = platforms.linux;
  };

}
