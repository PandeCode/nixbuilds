{
  lib,
  clangStdenv,
  copyDesktopItems,
  fetchFromGitHub,
  freetype,
  libGL,
  libx11,
  libxext,
  libxfixes,
  libxrandr,
  makeDesktopItem,
  pkg-config,
}:

clangStdenv.mkDerivation {
  pname = "raddebugger";
  # linux fixes land on master between the alpha tags
  version = "0.9.29-alpha-unstable-2026-10-20";

  src = fetchFromGitHub {
    owner = "EpicGames";
    repo = "raddebugger";
    rev = "bcf86a8b60ad7fc97cb9507992e48d41b3c0b921";
    hash = "sha256-PaEDEPChNiUmlFdBaOHCRCcsg3IQnT1/PaUyY89ixrA=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
  ];

  buildInputs = [
    freetype
    libGL
    libx11
    libxext
    libxfixes
    libxrandr
  ];

  buildPhase = ''
    runHook preBuild
    bash build.sh release raddbg radbin
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 build/raddbg build/radbin -t $out/bin
    install -Dm444 data/logo.png $out/share/icons/hicolor/256x256/apps/raddbg.png
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "raddbg";
      desktopName = "RAD Debugger";
      exec = "raddbg";
      icon = "raddbg";
      categories = [
        "Development"
        "Debugger"
      ];
    })
  ];

  meta = {
    description = "Native debugger with a graphical frontend, by Epic Games";
    homepage = "https://github.com/EpicGames/raddebugger";
    license = lib.licenses.mit;
    mainProgram = "raddbg";
    platforms = [ "x86_64-linux" ];
  };
}
