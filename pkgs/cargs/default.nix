{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "cargs";

  src = inputs.cargs;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
  meta = with lib; {
    description = "Simple command line argument parser library written in pure C";
    homepage = "https://github.com/likle/cargs";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}
