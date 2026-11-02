{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "opusfile-static";

  src = inputs.opusfile;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    liboggStatic
    libopusStatic
  ];

  cmakeFlags = [
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DBUILD_SHARED_LIBS=OFF"
    "-DOP_DISABLE_HTTP=ON"
    "-DOP_DISABLE_DOCS=ON"
    "-DOP_DISABLE_EXAMPLES=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Opus file decoding library (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/xiph/opusfile";
    license = licenses.bsdOriginal;
    platforms = platforms.linux;
  };
}
