{
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libserum";

  src = inputs.libserum;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DBUILD_SHARED=ON"
    "-DCMAKE_BUILD_TYPE=Release"
  ];
}
