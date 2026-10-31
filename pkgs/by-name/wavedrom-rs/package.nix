{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  pname = "wavedrom-rs";
  # no release since 0.1.0; pkgs/update.sh moves it to the newest commit
  version = "0.1.0-unstable-2026-05-04";

  src = fetchFromGitHub {
    owner = "coastalwhite";
    repo = "wavedrom-rs";
    rev = "8975d8e07b810edca143b9833b9aa9eeef5b6fd0";
    hash = "sha256-14u9TGXNosb/XPLObsI23hwCQvpldueZxRALIH8nWw8=";
  };

  cargoHash = "sha256-Trtkjv3JpT5xHe/LrgIaOgt1A8nwL8SByetAolV2DxA=";

  # the workspace also has the wasm demo and the mdbook preprocessor
  cargoBuildFlags = [
    "--package"
    "wavedrom"
  ];
  cargoTestFlags = [
    "--package"
    "wavedrom"
  ];

  meta = {
    description = "WaveDrom timing diagrams from WaveJSON to SVG, without javascript";
    homepage = "https://github.com/coastalwhite/wavedrom-rs";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "wavedrom";
  };
}
