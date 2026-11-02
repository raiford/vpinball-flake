{
  lib,
  pkgs,
  inputs,
}:
let
  pythonPackages = pkgs.python313Packages;
  # Release tag pinned by scripts/update_vpinfe (e.g. "v2.6.6" -> "2.6.6");
  # falls back to the short commit hash when the input is not tag-pinned.
  ver = lib.removePrefix "v" (inputs.vpinfeRelease or inputs.vpinfe.shortRev);
in
pythonPackages.buildPythonPackage {
  pname = "vpinfe";
  version = ver;

  format = "other";

  src = inputs.vpinfe;

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  # Runtime dependencies.
  #
  # Python deps mirror upstream requirements.txt (v2.6.6). vpinfe is a
  # NiceGUI web app that launches Chromium in --app kiosk mode per monitor
  # (frontend/chromium_manager.py); it does NOT use pywebview/GTK/webkit —
  # those were dependencies of the pre-2.0 pywebview architecture.
  #
  # - chromium: get_chromium_path() does which("chromium") on Linux before
  #   falling back to a bundled copy (the "slim build" behavior).
  # - libX11/libXrandr: screeninfo's X11 backend loads these via
  #   ctypes.util.find_library(), which on Linux resolves through
  #   `ld -t -L<dir>` (see _findLib_ld in CPython Lib/ctypes/util.py).
  #   binutils provides that `ld`; the wrapper adds the lib dirs to
  #   LD_LIBRARY_PATH so the store paths are found.
  buildInputs = with pkgs; [
    chromium
    libX11
    libXrandr
    binutils
  ];

  propagatedBuildInputs = with pythonPackages; [
    requests
    websockets
    screeninfo
    olefile
    pynput
    nicegui
    platformdirs
    pillow
    qrcode
    psutil
    rarfile
    py7zr
  ];

  # Upstream CI (".github/workflows/build.yml" -> "Set app version from
  # tag/commit") rewrites common/app_version.py with the release tag; the
  # AUR package does the same via sed.
  patchPhase = ''
    runHook prePatch
    sed -i "s/^APP_VERSION = .*$/APP_VERSION = \\\"v${ver}\\\"/" common/app_version.py
    runHook postPatch
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/vpinfe
    cp -r ./* $out/vpinfe/
    makeWrapper "$out/vpinfe/main.py" "$out/bin/vpinfe" \
      --prefix PYTHONPATH : $PYTHONPATH \
      --prefix LD_LIBRARY_PATH : "${pkgs.libX11}/lib:${pkgs.libXrandr}/lib"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Visual Pinball frontend for Linux, Mac, and Windows";
    homepage = "https://github.com/superhac/vpinfe";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "vpinfe";
  };
}
