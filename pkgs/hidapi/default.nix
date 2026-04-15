{
  lib,
  stdenv,
  pkgs,
  inputs,
}:
stdenv.mkDerivation {
  name = "hidapi";

  src = inputs.hidapi;

  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
  ];

  buildInputs = with pkgs; [
    systemd # for libudev
    libusb
  ];

  cmakeFlags = [
    "-DHIAPI_WITH_LIBUSB=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = with lib; {
    description = "Cross-platform library for USB and Bluetooth HID-class device access";
    homepage = "https://github.com/libusb/hidapi";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };

}
