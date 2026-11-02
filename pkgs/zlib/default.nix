{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "zlib-static";

  src = inputs.zlib;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DZLIB_BUILD_EXAMPLES=OFF"
    "-DZLIB_BUILD_TESTS=OFF"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "zlib compression library (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/madler/zlib";
    license = licenses.zlib;
    platforms = platforms.linux;
  };
}
