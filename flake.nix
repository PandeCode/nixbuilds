{
  description = "project templates";

  nixConfig = {
    trusted-users = ["root" "shawn"];
    experimental-features = ["nix-command" "flakes" "pipe-operators"];
    accept-flake-config = true;
    show-trace = true;
    auto-optimise-store = true;

    # substituters = ["https://aseipp-nix-cache.freetls.fastly.net"];

    extra-substituters = [
      "https://charon.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixutils = {
      url = "github:pandecode/nixutils";
      inputs.nixpkgs.follows = "nixutils";
    };

    hermes = {
      url = "github:pandecode/hermes";
      inputs.nixpkgs.follows = "nixutils";
    };
    libys = {
      url = "github:pandecode/libys";
      inputs.nixpkgs.follows = "nixutils";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixutils";
    };

    ghostty = {
      url = "github:ghostty-org/ghostty";
      inputs.nixpkgs.follows = "nixutils";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs.nixpkgs.follows = "nixutils";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixutils";
    };

    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixutils";
    };

    boomer.url = "github:nilp0inter/boomer";
  };

  outputs = inputs: let
    self = inputs.self.inputs // inputs.nixutils.inputs;
  in {
    nix.nixPath = ["nixpkgs=${self.inputs.nixpkgs}"];
    packages = self.inputs.nixutils.lib.forAllSystems ((import ./packages.nix) (self // {}));
  };
}
