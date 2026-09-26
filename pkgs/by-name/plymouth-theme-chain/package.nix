{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  imagemagick,
  unstableGitUpdater,
  # any of background, main, secondary, as uppercase "#RRGGBB"
  colors ? { },
}:

let
  recolor = lib.attrsets.mapAttrsToList (
    part: color: "bash change-color.sh ${part} ${lib.strings.escapeShellArg color}"
  ) colors;
in

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "plymouth-theme-chain";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "Hugopikachu";
    repo = "plymouth-theme-chain";
    rev = "v${finalAttrs.version}";
    hash = "sha256-qvCzYK5Ti/YH7c6rg0AJS/C/efe4cERLY9tS+WFmluM=";
  };

  nativeBuildInputs = lib.lists.optional (colors != { }) imagemagick;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    ${lib.strings.concatLines recolor}
    rm -fr README.md LICENSE preview change-color.sh
    sed -i "s@\/usr\/@$out\/@" chain.plymouth
    mkdir -p $out/share/plymouth/themes/chain
    cp -r ./* $out/share/plymouth/themes/chain

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "Plymouth boot theme with a chain animation";
    homepage = "https://github.com/Hugopikachu/plymouth-theme-chain";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
})
