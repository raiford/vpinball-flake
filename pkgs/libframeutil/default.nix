{
  lib,
  stdenv,
  inputs,
}:
stdenv.mkDerivation {
  name = "libframeutil";

  src = inputs.libframeutil;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/include
    cp -r include/* $out/include/

    runHook postInstall
  '';

  meta = with lib; {
    description = "Header-only utility library for DMD frame manipulation used by libzedmd";
    homepage = "https://github.com/ppuc/libframeutil";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
  };
}
