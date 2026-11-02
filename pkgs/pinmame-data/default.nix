{
  lib,
  stdenvNoCC,
  inputs,
}:
stdenvNoCC.mkDerivation {
  name = "pinmame-data";

  # Machine data fetched by upstream's external.sh, shipped next to the
  # pinmame plugin as its default data source.
  memmaps = inputs.pinmame-memmaps;
  gamedefs = inputs.pinmame-gamedefs;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/memmaps $out/gamedefs
    cp $memmaps/index.json $out/memmaps/
    cp -r $memmaps/maps $memmaps/platforms $out/memmaps/
    cp -r $gamedefs/catalog $gamedefs/machines $gamedefs/controllers $out/gamedefs/

    runHook postInstall
  '';

  meta = with lib; {
    description = "PinMAME machine data (memory maps and game definitions)";
    homepage = "https://github.com/vpinball/pinmame-game-defs";
    license = licenses.unfreeRedistributable;
    platforms = platforms.linux;
  };
}
