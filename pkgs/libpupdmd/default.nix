{
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "libpupdmd";

  src = inputs.libpupdmd;

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
