{
  lib,
  stdenv,
  pkgs,
  vpinPkgs,
  inputs,
  buildType ? "Release",
}:
stdenv.mkDerivation {
  name = "libdof";

  src = inputs.libdof;

  nativeBuildInputs = with pkgs; [
    cmake
  ];

  buildInputs = (with pkgs; [
    systemd # for libudev
  ])
  ++ (with vpinPkgs; [
    hidapi
    # libdof builds its own libserialport/libusb from its own config.sh
    # pins; the *Dof instances match them (and collapse to the canonical
    # instances when the upstream pins agree).
    libserialportDof
    libftdi
    libusbDof
  ]);

  cmakeFlags = [
    "-DPLATFORM=linux"
    "-DARCH=x64"
    "-DBUILD_STATIC=OFF"
    "-DPOST_BUILD_COPY_EXT_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=${buildType}"
  ];

  meta = with lib; {
    description = "Cross-platform C++ port of DirectOutput Framework for pinball feedback hardware";
    homepage = "https://github.com/jsm174/libdof";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
