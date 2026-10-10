{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  ffmpeg-headless,
  kdePackages,
  unstableGitUpdater,
  # image or video, the extension decides how the theme plays it
  background ? fetchurl {
    url = "https://github.com/PandeCode/nixutils/raw/refs/heads/media/sddm/factorio.mp4";
    sha256 = "0hrj4x8q068ih398gcjsr7ai6qb7mlj8mbdgcdqjcm98pjbchvaj";
  },
  # image shown while a video background loads, defaults to its first frame
  placeholder ? null,
  # keys from Themes/custom.conf, they override its defaults
  themeConfig ? { },
}:

let
  extension =
    file: lib.strings.toLower (lib.lists.last (lib.strings.splitString "." (baseNameOf file)));

  images = [
    "png"
    "jpg"
    "jpeg"
    "webp"
    "gif"
  ];
  videos = [
    "avi"
    "mp4"
    "mov"
    "mkv"
    "m4v"
    "webm"
  ];

  backgroundExt = extension background;
  isVideo = lib.lists.elem backgroundExt videos;
  placeholderExt = if placeholder == null then "png" else extension placeholder;

  # quoted so colors and empty strings survive qsettings
  quote = v: builtins.toJSON (if lib.isBool v then lib.boolToString v else toString v);
  userConfig = lib.generators.toINI { mkKeyValue = k: v: "${k}=${quote v}"; } {
    General = {
      Background = "Backgrounds/background.${backgroundExt}";
      BackgroundPlaceholder = lib.strings.optionalString isVideo "Backgrounds/placeholder.${placeholderExt}";
    }
    // themeConfig;
  };

  themeDir = "$out/share/sddm/themes/sddm-custom-theme";
in

assert lib.assertMsg (lib.lists.elem backgroundExt (images ++ videos))
  "sddm-custom-theme: background must be one of ${
    lib.strings.concatStringsSep ", " (images ++ videos)
  }, got '${backgroundExt}'";
assert lib.assertMsg (placeholder == null || lib.lists.elem placeholderExt images)
  "sddm-custom-theme: placeholder must be one of ${lib.strings.concatStringsSep ", " images}, got '${placeholderExt}'";

stdenvNoCC.mkDerivation {
  pname = "sddm-custom-theme";
  version = "0-unstable-2025-11-08";

  src = fetchFromGitHub {
    owner = "pandecode";
    repo = "sddm-custom-theme";
    rev = "fb1bbdb15b10b065a14058ef2513b286ffb14e2d";
    hash = "sha256-NmLsJoztWxZFuYqdi4EuxAxBnUIqMVxYfXN+IBHKkFA=";
  };

  nativeBuildInputs = lib.lists.optional (isVideo && placeholder == null) ffmpeg-headless;

  dontBuild = true;
  dontWrapQtApps = true;

  propagatedBuildInputs = with kdePackages; [
    qtsvg
    qtmultimedia
    qtvirtualkeyboard
  ];

  inherit userConfig;
  passAsFile = [ "userConfig" ];

  installPhase = ''
    runHook preInstall

    mkdir -p ${themeDir}/Backgrounds
    cp -r ./* ${themeDir}
    rm ${themeDir}/LICENSE

    cp ${background} ${themeDir}/Backgrounds/background.${backgroundExt}
    ${
      if !isVideo then
        ""
      else if placeholder == null then
        "ffmpeg -loglevel error -i ${background} -frames:v 1 ${themeDir}/Backgrounds/placeholder.png"
      else
        "cp ${placeholder} ${themeDir}/Backgrounds/placeholder.${placeholderExt}"
    }

    # sddm reads <ConfigFile>.user on top of the theme's own config
    cp $userConfigPath ${themeDir}/Themes/custom.conf.user

    # the greeter only sees fonts from fonts.packages
    mkdir -p $out/share/fonts/truetype
    ln -s ${themeDir}/Fonts/pixelon.regular.ttf $out/share/fonts/truetype/

    runHook postInstall
  '';

  passthru.updateScript = unstableGitUpdater { };

  meta = {
    description = "SDDM theme with a video background, based on sddm-astronaut-theme";
    homepage = "https://github.com/pandecode/sddm-custom-theme";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
