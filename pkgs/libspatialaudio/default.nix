{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libspatialaudio-static";

  src = inputs.libspatialaudio;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    libmysofaStatic
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Spatial audio library (ambisonics, HRTF) (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/videolan/libspatialaudio";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
