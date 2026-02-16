{
  stdenv,
  inputs,
}:
stdenv.mkDerivation {
  name = "libframeutil";

  src = inputs.libframeutil;

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/include
    cp -r include/* $out/include/
  '';
}
