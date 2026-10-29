{
  lib,
  fetchFromGitHub,
  haskell,
  haskellPackages,
}:

# nixpkgs builds the binary from hackage 0.2.0.1 (2024-05), which predates
# agda 2.7. this is master, with the agda 2.8 fixes; vimPlugins.cornelis picks
# it up through the overlay. its vim files are the same as the
# nvim-0.12-compat tag that vimPlugins.cornelis uses. that tag only changes
# the haskell side, for an nvim-hs that reads its api from a 0.12 nvim at
# build time; nixpkgs' nvim-hs uses its bundled api, which master builds with
let
  inherit (haskell.lib.compose) overrideCabal justStaticExecutables;
in

lib.pipe haskellPackages.cornelis [
  (overrideCabal {
    version = "0.2.0.1-unstable-2026-07-24";
    src = fetchFromGitHub {
      owner = "agda";
      repo = "cornelis";
      rev = "cddeac119a2fb3ecb093a28e35426b014c0963dd";
      hash = "sha256-OQlTqhs7ZwLbiby5v96upm2xQqQWLKqRMzoDynnM1BQ=";
    };
    # the suite needs agda and a running neovim
    doCheck = false;
    description = "agda-mode for Neovim";
  })
  justStaticExecutables
]
