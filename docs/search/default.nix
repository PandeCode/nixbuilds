# a search of every package here, with nuschtos search. baseHref is where it
# is served from: / locally, /nixbuilds/ on github pages
{
  inputs,
  packages,
  stdenv,
  baseHref ? "/",
}:

inputs.search.packages.${stdenv.hostPlatform.system}.mkSearch {
  title = "nixbuilds";
  inherit baseHref;
  pkgs = packages;
  # github pages has no fallback to index.html for other paths
  hashLocation = true;
  urlPrefix = "https://github.com/PandeCode/nixbuilds/blob/main/";
}
