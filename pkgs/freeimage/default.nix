{
  lib,
  stdenv,
  pkgs,
  inputs,
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
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    cp libfreeimage.{so,so.*} $out/lib

    runHook postInstall
  '';

  meta = with lib; {
    description = "Open source image library supporting common graphics file formats (toxieainc fork used by vpinball)";
    homepage = "https://github.com/toxieainc/freeimage";
    license = with licenses; [ freeimage gpl2Plus gpl3Plus ];
    platforms = platforms.linux;
  };

}
