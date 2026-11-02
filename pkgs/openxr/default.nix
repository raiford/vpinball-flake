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
    pkg-config
    # The pinned commit ships no pre-generated dispatch table; the build
    # generates it from XML at configure time.
    python3
  ];

  buildInputs = with pkgs; [
    # xlib presentation backend (the loader default) requires X11 headers
    libx11
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

  # The generated .pc file joins ${exec_prefix} with an absolute libdir,
  # producing "...//nix/store/..." which fails Nix's fixup phase.
  postInstall = ''
    substituteInPlace $out/lib/pkgconfig/openxr.pc \
      --replace-fail "//nix/store" "/nix/store"
  '';

  meta = with lib; {
    description = "OpenXR SDK runtime loader (SHA pinned by vpinball upstream)";
    homepage = "https://github.com/KhronosGroup/OpenXR-SDK-Source";
    license = licenses.asl20;
    platforms = platforms.linux;
  };
}
