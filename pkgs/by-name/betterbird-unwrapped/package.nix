# betterbird's own build, since nixpkgs dropped it. `betterbird` wraps it
# like nixpkgs' thunderbird-bin
{
  lib,
  stdenv,
  fetchurl,
  wrapGAppsHook3,
  autoPatchelfHook,
  patchelfUnstable,
  alsa-lib,
  gtk3,
  writeText,
}:

let
  version = "153.4.0esr-bb10";
  # a thunderbird- name gets the wrapper's mail categories and mime types
  libName = "thunderbird-betterbird-${version}";

  policies = writeText "betterbird-policies.json" (
    builtins.toJSON { policies.DisableAppUpdate = true; }
  );
in

stdenv.mkDerivation {
  pname = "betterbird-unwrapped";
  inherit version;

  src = fetchurl {
    url = "https://www.betterbird.eu/downloads/LinuxArchive/betterbird-${version}.en-US.linux-x86_64.tar.xz";
    hash = "sha256-ON0kiQpmtM+aRbwk4VGS4AwmuSnhu433l0wWpFORKeI=";
  };

  nativeBuildInputs = [
    wrapGAppsHook3
    autoPatchelfHook
    patchelfUnstable
  ];
  buildInputs = [ alsa-lib ];

  # it handles some relocations itself, from fixed offsets
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/${libName}/distribution $out/bin
    cp -r * $out/lib/${libName}
    ln -s $out/lib/${libName}/betterbird $out/bin/
    ln -s ${policies} $out/lib/${libName}/distribution/policies.json
    gappsWrapperArgs+=(--argv0 "$out/bin/.betterbird-wrapped")
    runHook postInstall
  '';

  passthru = {
    inherit gtk3 libName;
    applicationName = "Betterbird";
    binaryName = "betterbird";
  };

  meta = {
    description = "Thunderbird with fixes and extras";
    homepage = "https://www.betterbird.eu";
    license = lib.licenses.mpl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "betterbird";
  };
}
