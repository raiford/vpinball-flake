{
  lib,
  pkgs,
  inputs,
}:
let
  pythonPackages = pkgs.python313Packages;
in
pythonPackages.buildPythonPackage {
  pname = "vpinfe";
  version = "unstable-2026-02-23";

  format = "other";

  src = inputs.vpinfe;

  nativeBuildInputs = with pkgs; [
    makeWrapper
    wrapGAppsHook3
    wrapGAppsHook4
  ];

  propagatedBuildInputs = with pythonPackages; [
    requests
    pywebview
    screeninfo
    olefile
    pynput
    nicegui
    platformdirs
    pygobject3
    pkgs.wrapGAppsHook3
    pkgs.wrapGAppsHook4
    pkgs.gtk3
    pkgs.gobject-introspection
    pkgs.webkitgtk_4_1
    pkgs.webkitgtk_6_0
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/vpinfe
    cp -r ./* $out/vpinfe/
    makeWrapper "$out/vpinfe/main.py" "$out/bin/vpinfe" --prefix PYTHONPATH : $PYTHONPATH
    runHook postInstall
  '';

  meta = with lib; {
    description = "Visual Pinball frontend for Linux, Mac, and Windows";
    homepage = "https://github.com/superhac/vpinfe";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
