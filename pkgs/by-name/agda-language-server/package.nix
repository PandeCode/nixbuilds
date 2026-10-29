{
  lib,
  fetchFromGitHub,
  haskell,
  haskellPackages,
}:

# nixpkgs has 0.2.6.3.0 from hackage, which wants agda 2.6.3 and is marked
# broken. v9 builds against the agda 2.8.0 nixpkgs ships
let
  als =
    {
      mkDerivation,
      hpack,
      aeson,
      Agda,
      base,
      bytestring,
      containers,
      directory,
      filepath,
      lsp,
      lsp-types,
      mtl,
      network,
      network-simple,
      prettyprinter,
      process,
      stm,
      strict,
      text,
    }:
    mkDerivation rec {
      pname = "agda-language-server";
      version = "9";

      src = fetchFromGitHub {
        owner = "agda";
        repo = "agda-language-server";
        tag = "v${version}";
        hash = "sha256-W/MvABmv7wWcxLmaFXcGwtIDyd7U3YxF3lj0JSO2Je4=";
      };

      # the .cabal file is generated from package.yaml. it pins network-simple
      # 0.4.2, nixpkgs has a newer one
      prePatch = ''
        sed -i 's/network-simple == 0.4.2/network-simple/' package.yaml
        hpack
      '';

      configureFlags = [ "-fAgda-2-8-0" ];

      isLibrary = false;
      isExecutable = true;

      libraryToolDepends = [ hpack ];

      executableHaskellDepends = [
        aeson
        Agda
        base
        bytestring
        containers
        directory
        filepath
        lsp
        lsp-types
        mtl
        network
        network-simple
        prettyprinter
        process
        stm
        strict
        text
      ];

      # the suite type checks agda files and talks to a running server
      doCheck = false;

      description = "Language server for Agda";
      homepage = "https://github.com/agda/agda-language-server";
      license = lib.licenses.mit;
      mainProgram = "als";
    };
in

haskell.lib.compose.justStaticExecutables (haskellPackages.callPackage als { })
