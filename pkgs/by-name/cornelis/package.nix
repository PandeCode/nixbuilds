{
  lib,
  fetchFromGitHub,
  haskell,
  haskellPackages,
}:

# nixpkgs builds the binary from hackage 0.2.0.1 (2024-05), which predates
# agda 2.7, while vimPlugins.cornelis is already at nvim-0.12-compat. this
# builds the binary from that same tag, and vimPlugins.cornelis picks it up
# through the overlay
let
  inherit (haskell.lib.compose) overrideCabal justStaticExecutables;
in

lib.pipe haskellPackages.cornelis [
  (overrideCabal {
    version = "0.2.0.1-unstable-2026-07-06";
    src = fetchFromGitHub {
      owner = "agda";
      repo = "cornelis";
      tag = "nvim-0.12-compat";
      hash = "sha256-ObmnsH25/vnC6TEJ44ZZuJJBrnnAJuDNYkJZU6YnTi4=";
    };
    # the suite needs agda and a running neovim
    doCheck = false;
    description = "agda-mode for Neovim";
  })
  justStaticExecutables
]
