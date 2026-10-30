# builds and installs ios apps from linux. xtool drives swift.org's own
# toolchain (nixpkgs' swift lags behind what xtool needs and is wrapped for
# linux only), so both run in one fhs env. the darwin sdk comes from your own
# Xcode.xip through `xtool setup`
{
  lib,
  appimageTools,
  autoPatchelfHook,
  buildFHSEnv,
  curl,
  fetchurl,
  libedit,
  libuuid,
  libxml2_13,
  makeWrapper,
  ncurses,
  python312,
  runCommand,
  sqlite,
  stdenv,
  zlib,
}:

let
  pname = "xtool";
  version = "1.9.2";

  src = fetchurl {
    url = "https://github.com/xtool-org/xtool/releases/download/${version}/xtool-x86_64.AppImage";
    hash = "sha256-TpZSRz1uoMO9Ce5igfUqh6UWxgSD8/hMN2r3IurIPCc=";
  };

  # the binary finds its bundled libs through $ORIGIN/../lib, so it stays out
  # of the env's /usr/lib where those old libs would shadow the toolchain's
  contents = appimageTools.extract { inherit pname version src; };

  # match the swift that xtool's docs ask for, the darwin sdk from Xcode
  # only loads in a compiler at least as new as Xcode's own
  toolchain = stdenv.mkDerivation (finalAttrs: {
    pname = "swift-toolchain";
    version = "6.4.2";

    src = fetchurl {
      url = "https://download.swift.org/swift-${finalAttrs.version}-release/ubuntu2404/swift-${finalAttrs.version}-RELEASE/swift-${finalAttrs.version}-RELEASE-ubuntu24.04.tar.gz";
      hash = "sha256-Lp6+wECtRZ3Ymm0JOgLYMUk5E1EEhQ+uTVwPF0+zuow=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];

    # the sonames ubuntu ships, libxml2 2.14 bumped its own
    buildInputs = [
      # keep-sorted start
      curl
      libedit
      libuuid
      libxml2_13
      ncurses
      python312
      sqlite
      stdenv.cc.cc.lib
      zlib
      # keep-sorted end
    ];

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    # swift-build finds the toolchain's own paths from <root>/usr/bin/swift,
    # the links at the top are for the fhs env
    installPhase = ''
      mkdir $out
      mv usr $out
      for dir in $out/usr/*; do
        ln -s usr/''${dir##*/} $out
      done
    '';

    # debian renames libedit.so.0 to .2, same abi
    preFixup = ''
      for f in $(grep -rlF libedit.so.2 $out/usr/bin $out/usr/lib); do
        patchelf --replace-needed libedit.so.2 libedit.so.0 "$f"
      done
    '';
  });

  env = buildFHSEnv {
    pname = "xtool-env";
    inherit version;

    # swift links the package manifests with gcc's crt files and glibc's
    # headers, the rest is what swift.org lists for ubuntu 24.04
    targetPkgs =
      pkgs: with pkgs; [
        # keep-sorted start
        binutils
        # libcom_err for the libs bundled with xtool
        e2fsprogs
        gcc
        # lib/gcc with the crt files and libgcc, which clang looks for
        gcc.cc
        git
        glibc.dev
        # libgmp for the libs bundled with xtool
        gmp
        pkg-config
        toolchain
        tzdata
        unzip
        zlib
        # keep-sorted end
      ];

    runScript = "env";
  };
in

runCommand "${pname}-${version}"
  {
    nativeBuildInputs = [ makeWrapper ];

    meta = {
      description = "Cross-platform Xcode replacement for building and installing iOS apps";
      homepage = "https://xtool.sh";
      license = lib.licenses.mit;
      mainProgram = "xtool";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  }
  ''
    makeWrapper ${env}/bin/xtool-env $out/bin/xtool --add-flags ${contents}/usr/bin/xtool
    for prog in swift sourcekit-lsp; do
      makeWrapper ${env}/bin/xtool-env $out/bin/$prog --add-flags $prog
    done
  ''
