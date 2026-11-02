{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libopus-static";

  src = inputs.libopus;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DOPUS_BUILD_PROGRAMS=OFF"
    "-DOPUS_BUILD_TESTING=OFF"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Opus audio codec (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/xiph/opus";
    license = licenses.bsdOriginal;
    platforms = platforms.linux;
  };
}
