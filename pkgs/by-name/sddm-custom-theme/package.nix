{
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
  kdePackages,
  video ? fetchurl {
    url = "https://github.com/PandeCode/nixutils/raw/refs/heads/media/sddm/factorio.mp4";
    sha256 = "0hrj4x8q068ih398gcjsr7ai6qb7mlj8mbdgcdqjcm98pjbchvaj";
  },
  placeholder ? fetchurl {
    url = "https://github.com/PandeCode/nixutils/raw/refs/heads/media/sddm/factorio.png";
    sha256 = "0g6ph1zqfrqqclswd5xnczdj0rkw26sn168f3260kcd43cx7100b";
  },
}:

stdenvNoCC.mkDerivation {
  pname = "sddm-custom-theme";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "pandecode";
    repo = "sddm-custom-theme";
    rev = "fb1bbdb15b10b065a14058ef2513b286ffb14e2d";
    hash = "sha256-NmLsJoztWxZFuYqdi4EuxAxBnUIqMVxYfXN+IBHKkFA=";
  };

  dontWrapQtApps = true;

  propagatedBuildInputs = with kdePackages; [
    qtsvg
    qtmultimedia
    qtvirtualkeyboard
  ];

  installPhase =
    let
      basePath = "$out/share/sddm/themes/sddm-custom-theme";
    in
    ''
      mkdir -p ${basePath}
      mkdir -p ${basePath}/Backgrounds

      cp -r $src/* ${basePath}

      cp -f ${video} ${basePath}/Backgrounds/custom.mp4
      cp -f ${placeholder} ${basePath}/Backgrounds/custom.png
    '';
}
