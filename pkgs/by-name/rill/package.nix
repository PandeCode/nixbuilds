{
  lib,
  stdenv,
  fetchFromCodeberg,
  fetchzip,
  linkFarm,
  libxkbcommon,
  pkg-config,
  wayland,
  wayland-protocols,
  wayland-scanner,
  zig_0_16,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rill";
  # pinned 2026-09-15, rill has no releases
  version = "0.7.0-unstable-2026-10-01";

  src = fetchFromCodeberg {
    owner = "lzj15";
    repo = "rill";
    rev = "b35a0fd022e015f0c3e43f892555d73e0643bcfa";
    hash = "sha256-vVXE0OF2qZI/LIzzOAoaoT7+ARcVI+cftSXdQ6pniTQ=";
  };

  # generated with zon2nix from build.zig.zon at the rev above
  deps = linkFarm "rill-zig-deps" [
    {
      name = "N-V-__8AAA3xAgD5Kwpwii8EK-ddKekNkv4zv8rJiDhDHLuI";
      path = fetchzip {
        url = "https://codeberg.org/river/river/archive/v0.4.8:protocol.tar.gz";
        hash = "sha256-KsgaDFg3lQGt53sCKXumYmWWfuH3iritU211fnuZkJQ=";
      };
    }
    {
      name = "wayland-0.6.0-lQa1kqz8AQADQmdNJsNhLoNHcnEGEUjrOaPV-dtEnEmX";
      path = fetchzip {
        url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.6.0.tar.gz";
        hash = "sha256-3m/ITNhZUJ/5uD/Tqm+0uZSktGoYgWF5oldOqOCUkIE=";
      };
    }
    {
      name = "xkbcommon-0.4.0-VDqIe0i2AgDRsok2GpMFYJ8SVhQS10_PI2M_CnHXsJJZ";
      path = fetchzip {
        url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.4.0.tar.gz";
        hash = "sha256-zQkmP/cuhAtjOLqYS5D15khKzpqyhbyZ0TD6/8jOkqE=";
      };
    }
  ];

  strictDeps = true;

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
    zig_0_16
  ];

  # wayland-scanner in both, like nixpkgs' river: zig-wayland finds it
  # through pkg-config
  buildInputs = [
    libxkbcommon
    wayland
    wayland-protocols
    wayland-scanner
  ];

  zigBuildFlags = [
    "--system"
    "${finalAttrs.deps}"
  ];

  meta = {
    description = "Scrolling window manager for river";
    homepage = "https://codeberg.org/lzj15/rill";
    mainProgram = "rill";
    platforms = lib.platforms.linux;
  };
})
