# vscodium's own server build, the editor in a browser. nixpkgs only has
# the desktop app
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  krb5,
  nodejs_24,
  writeText,
  # new defaults for any setting, `{ "telemetry.telemetryLevel" = "off"; }`.
  # they go in as a built-in extension, so settings.json still wins
  settings ? { },
}:

let
  defaults = writeText "package.json" (
    builtins.toJSON {
      name = "defaults";
      publisher = "local";
      version = "1.0.0";
      engines.vscode = "*";
      contributes.configurationDefaults = settings;
    }
  );
in

stdenv.mkDerivation (finalAttrs: {
  pname = "vscodium-server";
  version = "1.143.17232";

  src = fetchurl {
    url = "https://github.com/VSCodium/vscodium/releases/download/${finalAttrs.version}/vscodium-reh-web-linux-x64-${finalAttrs.version}.tar.gz";
    hash = "sha256-DR4A+k41ZGF6unmKiDldml+1B9dx1xHgRUuxBloDD3w=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    krb5
    stdenv.cc.cc.lib
  ];

  # microsoft account logins, which also want a desktop's worth of
  # libraries. its own node segfaults once patched, so nixpkgs' node of the
  # same version runs it
  postPatch = ''
    rm -r extensions/microsoft-authentication
    rm node
    ln -s ${lib.meta.getExe nodejs_24} node
  ''
  + lib.strings.optionalString (settings != { }) ''
    install -Dm444 ${defaults} extensions/local-defaults/package.json
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/vscodium-server $out/bin
    cp -r . $out/lib/vscodium-server
    ln -s $out/lib/vscodium-server/bin/codium-server $out/bin/codium-server
    runHook postInstall
  '';

  meta = {
    description = "VSCodium served to a browser";
    homepage = "https://github.com/VSCodium/vscodium";
    license = lib.licenses.mit;
    mainProgram = "codium-server";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
