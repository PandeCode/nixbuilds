{
  description = "personal nixpkgs";

  # lets people who use these packages download them instead of building
  nixConfig = {
    extra-substituters = [ "https://charon.cachix.org" ];
    extra-trusted-public-keys = [
      "charon.cachix.org-1:epdetEs1ll8oi8DT8OG2jEA4whj3FDbqgPFvapEPbY8="
    ];
  };

  outputs = inputs: import ./flake inputs;

  inputs = {
    # the nixpkgs pin for all my repos, they follow this one
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

    # my lib and the shared formatter config
    nixutils = {
      type = "github";
      owner = "PandeCode";
      repo = "nixutils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ### packages from other flakes, built against this nixpkgs and cached
    # run binaries that are not patched for nixos
    nix-alien = {
      type = "github";
      owner = "thiagokokada";
      repo = "nix-alien";

      # its nix-index-database already follows its nixpkgs
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };

    # zig built from master
    zig-overlay = {
      type = "github";
      owner = "mitchellh";
      repo = "zig-overlay";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "";
      };
    };

    # factory game main menu login screen
    sddm-foundry-theme = {
      type = "github";
      owner = "PandeCode";
      repo = "sddm-foundry-theme";

      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixutils.follows = "nixutils";
      };
    };
  };
}
