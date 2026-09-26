{
  lib,
  appimageTools,
  fetchurl,
}:

let
  pname = "helium";
  version = "0.18.1.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-0eG5k9+/7gbp+Q6KKc1Y6HpHUZewT8BIdQYifDOFacs=";
  };

  contents = appimageTools.extract { inherit pname version src; };
in

appimageTools.wrapType2 {
  inherit pname version src;

  # the desktop entry already runs `helium` with icon `helium`
  extraInstallCommands = ''
    install -Dm444 ${contents}/helium.desktop -t $out/share/applications
    install -Dm444 ${contents}/helium.png -t $out/share/icons/hicolor/256x256/apps
  '';

  meta = {
    description = "Chromium-based web browser";
    homepage = "https://github.com/imputnet/helium-linux";
    license = lib.licenses.gpl3Only;
    mainProgram = "helium";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
