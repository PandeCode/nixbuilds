{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  nodejs,
  yarnConfigHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "excalidraw";
  # the app has no releases; excalidraw.com runs the newest commit
  version = "0-unstable-2026-10-12";

  src = fetchFromGitHub {
    owner = "excalidraw";
    repo = "excalidraw";
    rev = "541653c7c9d587d463a47daacff9fb30e45a52e7";
    hash = "sha256-4lElC9p+ljpAw+Joy5/XPG1SEHCUi8FU4RIjvGqLFkA=";
  };

  offlineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = "sha256-Fib09SBYwALGpa00t+f+xyFGbu+6hxIUME2M5wN6+5o=";
  };

  # fonts from this site instead of excalidraw's cdn, and no analytics
  # script from simple analytics
  postPatch = ''
    substituteInPlace scripts/woff2/woff2-vite-plugins.js \
      --replace-fail '"https://excalidraw.nyc3.cdn.digitaloceanspaces.com/oss/"' '"/"'
    substituteInPlace excalidraw-app/index.html \
      --replace-fail '<!-- 100% privacy friendly analytics -->' '<% } if (false) { %>'
  '';

  nativeBuildInputs = [
    nodejs
    yarnConfigHook
  ];

  # the same build as its docker image: no error reports to sentry and no
  # tracking. sharing, live collaboration and the ai tools still go to
  # excalidraw.com, but only when you use them
  buildPhase = ''
    runHook preBuild
    cd excalidraw-app
    VITE_APP_DISABLE_SENTRY=true VITE_APP_ENABLE_TRACKING=false \
      VITE_APP_GIT_SHA=${finalAttrs.src.rev} node ../node_modules/vite/bin/vite.js build
    cd ..
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r excalidraw-app/build $out
    cp -r packages/excalidraw/fonts/Assistant $out/fonts
    # its fonts are bundled, so it needn't warm up a connection to google
    sed -i 's|<link rel="preconnect" href="https://fonts\.[^>]*>||g' $out/index.html
    find $out -name '*.map' -delete
    runHook postInstall
  '';

  meta = {
    description = "Whiteboard for hand-drawn looking sketches and diagrams";
    homepage = "https://github.com/excalidraw/excalidraw";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
