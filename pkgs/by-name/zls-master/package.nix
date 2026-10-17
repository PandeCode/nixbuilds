{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchzip,
  linkFarm,
  zig_0_17,
}:

# nixpkgs stops at zls 0.16 and zls has no 0.17 tag yet, master already
# needs zig 0.17.0. drop this for zls_0_17 once nixpkgs has it
stdenv.mkDerivation (finalAttrs: {
  pname = "zls";
  version = "0.17.0-unstable-2026-10-17";

  src = fetchFromGitHub {
    owner = "zigtools";
    repo = "zls";
    rev = "e867669b0ad2f200ef577f7eb1e8e7ebbb2e714c";
    hash = "sha256-6hYeSm4jREa5O+5FkQzNOM57ZKkT/lEiz0f+1iEIPmk=";
  };

  # copied from deps.nix at the rev above
  deps = linkFarm "zls-zig-deps" [
    {
      name = "known_folders-0.0.0-Fy-PJiDLAAB98m3uYUzatrTb2mO2fpvwx2zpSroEtfbO";
      path = fetchzip {
        url = "https://github.com/ziglibs/known-folders/archive/6da0d0c41b78b9ed2d34fa364fcb81b5ebece6c4.tar.gz";
        hash = "sha256-F17Ivvsyyla2CBIh+kImc1O3AtD2yTDAGamzMVbVzuw=";
      };
    }
    {
      name = "diffz-0.0.1-G2tlISvOAQDORzPTSxDgiKwlHuADKeJMdJrw4kRfLufj";
      path = fetchzip {
        url = "https://github.com/ziglibs/diffz/archive/aac8aa99c436ab8277b0711922aad062c0167b12.tar.gz";
        hash = "sha256-GQ4iCZSSpVvdDQteoi02keLSqSoDOSQPH8eihum++Z0=";
      };
    }
    {
      name = "lsp_kit-0.1.0-bi_PL9o2DADHS1PDra3MGz1MXnsboN_ewNvrc419z7Fb";
      path = fetchzip {
        url = "https://github.com/zigtools/lsp-kit/archive/3e1058db66079911fdde82f833fdce6856e0a706.tar.gz";
        hash = "sha256-vsTBPP9Rf7xoVyGyi3+j9a03mLqU/gwrdDKIpFTH2v0=";
      };
    }
  ];

  strictDeps = true;

  nativeBuildInputs = [ zig_0_17 ];

  # a dev version asks git for the rest of the version string, there is no
  # .git in the source
  zigBuildFlags = [
    "--system"
    "${finalAttrs.deps}"
    "-Dversion-string=0.17.0-dev+${builtins.substring 0 7 finalAttrs.src.rev}"
  ];

  meta = {
    description = "Zig language server, built from master for zig 0.17";
    homepage = "https://github.com/zigtools/zls";
    license = lib.licenses.mit;
    mainProgram = "zls";
    platforms = lib.platforms.unix;
  };
})
