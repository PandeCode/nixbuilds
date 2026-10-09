# chromium extensions, pinned: give `extensions` to
# programs.chromium.extensions. building this fetches them all, so ci checks
# the pins and charon caches them. pkgs/update.sh rewrites extensions.nix
{
  lib,
  fetchurl,
  linkFarm,
  ungoogled-chromium,
}:

let
  # the store serves the newest file this chromium can run
  prodversion = lib.versions.major ungoogled-chromium.version;

  url =
    e:
    if e ? github then
      "https://github.com/${e.github}/releases/download/${e.version}/${
        lib.strings.replaceStrings [ "@version@" ] [ e.version ] e.asset
      }"
    else
      "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${prodversion}&x=id%3D${e.id}%26installsource%3Dondemand%26uc";

  extensions = lib.attrsets.mapAttrsToList (_: e: {
    inherit (e) id version;
    crxPath = fetchurl {
      name = "${e.id}.crx";
      url = url e;
      inherit (e) hash;
    };
  }) (import ./extensions.nix);
in

(linkFarm "chromium-extensions" (
  map (e: {
    name = "${e.id}.crx";
    path = e.crxPath;
  }) extensions
)).overrideAttrs
  {
    passthru = { inherit extensions; };
  }
