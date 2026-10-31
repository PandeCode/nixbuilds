{
  lib,
  stdenv,
  fetchFromCodeberg,
  libxkbcommon,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
  zig_0_17,
}:

let
  zig = zig_0_17;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "rill";
  # rill has no releases; pkgs/update.sh moves it to the newest commit
  version = "0.7.0-unstable-2026-10-27";

  src = fetchFromCodeberg {
    owner = "lzj15";
    repo = "rill";
    rev = "7b3ce20659218c86cf25ff66a2e600af03b33cf7";
    hash = "sha256-bILoaiSoD44OK21nuM5dD0MJyQze4vLJSqfbylHcAw4=";
  };

  strictDeps = true;

  # one hash for every package in build.zig.zon, so nix-update (and the
  # weekly bot) refreshes it with the source instead of leaving it behind
  zigDeps = zig.fetchDeps {
    inherit (finalAttrs) src pname version;
    hash = "sha256-rOsFulT8MvLIB5UEySl2biLoyMxTUCVbWbIkz4pZ/go=";
  };

  postConfigure = ''
    ln -s ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
    zig
  ];

  # wayland-scanner in both, like nixpkgs' river: zig-wayland finds it
  # through pkg-config
  buildInputs = [
    libxkbcommon
    wayland
    wayland-protocols
    wayland-scanner
  ];

  meta = {
    description = "Scrolling window manager for river";
    homepage = "https://codeberg.org/lzj15/rill";
    mainProgram = "rill";
    platforms = lib.platforms.linux;
  };
})
