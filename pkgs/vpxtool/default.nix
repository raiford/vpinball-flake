{
  lib,
  pkgs,
  inputs,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  name = "vpxtool";
  #version = inputs.vpxtool.ref; # Placeholder version, can be updated later

  src = inputs.vpxtool;

  cargoLock = {
    lockFile = "${inputs.vpxtool}/Cargo.lock";
  };

  buildInputs = [
    pkgs.openssl
    pkgs.pkg-config
  ];

  meta = with lib; {
    description = "Command line tool to manipulate VPX (Visual Pinball X) files";
    homepage = "https://github.com/francisdb/vpxtool";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
