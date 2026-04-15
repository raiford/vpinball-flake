{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "sockpp";

  src = inputs.sockpp;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Simple, modern, C++ socket library wrapping BSD sockets and related APIs";
    homepage = "https://github.com/fpagliughi/sockpp";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
