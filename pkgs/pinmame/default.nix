{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "pinmame";
  #version = "changeme";

  src = inputs.pinmame;

  postUnpack = ''
    cp source/cmake/libpinmame/CMakeLists.txt source/CMakeLists.txt
  '';

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    zlib
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
  ];

  meta = with lib; {
    description = "Pinball emulator based on MAME, built as libpinmame for vpinball (vbousquet fork)";
    homepage = "https://github.com/vbousquet/pinmame";
    # Mixed: newer files are BSD-3-Clause, legacy files remain under the non-commercial
    # "old MAME" license. Treat the whole as unfreeRedistributable to be safe.
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
  };

}
