{
  lib,
  stdenv,
  pkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libspatialaudio-static";

  src = inputs.libspatialaudio;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = with pkgs; [
    libmysofaStatic
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  # The generated .pc file joins ${prefix} with an absolute libdir,
  # producing "${prefix}//nix/store/..." which fails Nix's fixup phase.
  postInstall = ''
    substituteInPlace $out/lib/pkgconfig/spatialaudio.pc \
      --replace-fail "//nix/store" "/nix/store"
  '';

  meta = with lib; {
    description = "Spatial audio library (ambisonics, HRTF) (static, SHA pinned by vpinball upstream)";
    homepage = "https://github.com/videolan/libspatialaudio";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
