{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libmysofa-static";

  src = inputs.libmysofa;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    zlibStatic
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DBUILD_STATIC_LIBS=ON"
    "-DBUILD_TESTS=OFF"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "SOFA file reader for HRTF spatial audio (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/hoene/libmysofa";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
