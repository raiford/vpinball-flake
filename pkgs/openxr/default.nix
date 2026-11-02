{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "openxr";

  src = inputs.openxr;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  cmakeFlags = [
    "-DBUILD_WITH_SYSTEM_JSONCPP=OFF"
    "-DBUILD_TESTS=OFF"
    "-DBUILD_API_LAYERS=OFF"
    "-DCMAKE_DISABLE_FIND_PACKAGE_OpenGL=ON"
    "-DCMAKE_DISABLE_FIND_PACKAGE_OpenGLES=ON"
    "-DDYNAMIC_LOADER=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "OpenXR SDK runtime loader (SHA pinned by vpinball upstream)";
    homepage = "https://github.com/KhronosGroup/OpenXR-SDK-Source";
    license = licenses.apache20;
    platforms = platforms.linux;
  };
}
