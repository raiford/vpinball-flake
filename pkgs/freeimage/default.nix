{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "freeimage";

  src = inputs.freeimage;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp libfreeimage.{so,so.*} $out/lib

    mkdir -p $out/include
    cp ../Source/FreeImage.h $out/include/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source image library supporting common graphics file formats (toxieainc fork used by vpinball)";
    homepage = "https://github.com/toxieainc/freeimage";
    license = with licenses; [
      {
        fullName = "FreeImage Public License - Version 1.0";
        url = "https://freeimage.sourceforge.io/freeimage-license.txt";
        free = true;
      }
      gpl2Plus
      gpl3Plus
    ];
    platforms = platforms.linux;
  };

}
