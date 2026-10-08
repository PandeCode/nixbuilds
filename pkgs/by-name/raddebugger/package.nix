{
  lib,
  clangStdenv,
  copyDesktopItems,
  fetchFromGitHub,
  freetype,
  libGL,
  libX11,
  libXext,
  libXfixes,
  libXrandr,
  makeDesktopItem,
  pkg-config,
}:

clangStdenv.mkDerivation {
  pname = "raddebugger";
  # linux fixes land on master between the alpha tags
  version = "0.9.29-alpha-unstable-2026-10-07";

  src = fetchFromGitHub {
    owner = "EpicGames";
    repo = "raddebugger";
    rev = "b6d8c3fd9eaf7b55960d80738365742a8fba9e29";
    hash = "sha256-rBGvDwYTX+s7ArSxBBeEWbGLF031OaOfubK8+KUl+xU=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    copyDesktopItems
    pkg-config
  ];

  buildInputs = [
    freetype
    libGL
    libX11
    libXext
    libXfixes
    libXrandr
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
