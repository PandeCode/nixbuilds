{
  appimageTools,
  fetchurl,
  makeDesktopItem,
  copyDesktopItems,
}:
appimageTools.wrapType2 (finalAttrs: rec {
  pname = "helium";
  version = "0.14.5.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${finalAttrs.version}/helium-${finalAttrs.version}-x86_64.AppImage";
    hash = "sha256-JM4Tm4Le9Xcfq3fFMEu/DIK6817FEgBQ2rSwY093F04=";
  };

  buildInputs = [copyDesktopItems];

  # ERROR not working
  desktopItems = [
    (makeDesktopItem {
      desktopName = "Helium";
      name = pname;
      exec = pname;
      icon = pname;
      genericName = "Web Browser";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
      actions = {
        new-window = {
          name = "New Window";
          exec = "${pname} --new-window %U";
        };
        new-private-window = {
          name = "New Private Window";
          exec = "${pname} --private-window %U";
        };
        profile-manager-window = {
          name = "Profile Manager";
          exec = "${pname} --ProfileManager";
        };
      };
    })
  ];

  passthru = {
    homeManagerModule = {
      pkgs,
      lib,
      ...
    }: {
      options = {
        helium = {
          enable = lib.mkOption {default = false;};
        };
      };
      config = {
      };
    };
  };
})
