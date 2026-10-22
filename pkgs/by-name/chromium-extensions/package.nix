# chromium extensions, pinned: give `extensions` to
# programs.chromium.extensions. building this fetches them all, so ci checks
# the pins and charon caches them. pkgs/update.sh rewrites extensions.nix,
# keeping each name, which the description lists for the package search
{
  lib,
  fetchurl,
  linkFarm,
  ungoogled-chromium,
}:

let
  # the store serves the newest file this chromium can run
  prodversion = lib.versions.major ungoogled-chromium.version;

  pins = import ./extensions.nix;
  # an entry without a name shows its key
  named = lib.attrsets.mapAttrsToList (key: e: e // { name = e.name or key; }) pins;

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
  }) pins;
in

(linkFarm "chromium-extensions" (
  map (e: {
    name = "${e.id}.crx";
    path = e.crxPath;
  }) extensions
)).overrideAttrs
  (old: {
    passthru = { inherit extensions; };

    meta = old.meta or { } // {
      description = "Chromium extensions: " + lib.strings.concatMapStringsSep ", " (e: e.name) named;
      longDescription = lib.strings.concatMapStrings (e: "- ${e.name} ${e.version}\n") named;
    };
  })
