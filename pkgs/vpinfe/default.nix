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
  # Release tag pinned by scripts/update_vpinfe (e.g. "v2.6.6" -> "2.6.6");
  # falls back to the short commit hash when the input is not tag-pinned.
  version = lib.removePrefix "v" (inputs.vpinfeRelease or inputs.vpinfe.shortRev);

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
