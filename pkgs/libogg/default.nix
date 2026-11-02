{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libogg-static";

  src = inputs.libogg;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DINSTALL_DOCS=OFF"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Ogg bitstream library (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/xiph/ogg";
    license = licenses.bsdOriginal;
    platforms = platforms.linux;
  };
}
