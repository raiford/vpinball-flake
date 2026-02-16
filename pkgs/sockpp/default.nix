{
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
}
