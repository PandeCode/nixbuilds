inputs:

let
  inherit (inputs) nixpkgs nixutils self;
  inherit (nixpkgs) lib;

  # nixpkgs with my packages on top. unfree is allowed so the unfree
  # packages here can be built and cached
  forAllPkgs =
    fn:
    nixutils.lib.forAllSystems (
      system:
      fn (
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.default ];
        }
      )
    );

  mine =
    final: prev:
    import ../pkgs {
      pkgs = final;
      inherit (prev) lib;
      inherit (prev.stdenv.hostPlatform) system;
      inherit inputs;
    };
in

{
  overlays.default = mine;

  # everything, including `toolsets`
  legacyPackages = forAllPkgs (pkgs: mine pkgs pkgs);

  packages = forAllPkgs (
    pkgs:
    lib.attrsets.filterAttrs (
      _: pkg: lib.attrsets.isDerivation pkg && lib.meta.availableOn pkgs.stdenv.hostPlatform pkg
    ) (mine pkgs pkgs)
  );

  # building every package is the check; CI pushes the results to charon
  checks = forAllPkgs (
    pkgs:
    self.packages.${pkgs.stdenv.hostPlatform.system}
    // {
      formatting = self.formatter.${pkgs.stdenv.hostPlatform.system}.check self;
    }
  );

  formatter = forAllPkgs (pkgs: pkgs.treefmt.withConfig nixutils.lib.treefmtModule);

  devShells = forAllPkgs (pkgs: {
    default = pkgs.mkShellNoCC {
      packages = [
        # for pkgs/update.sh
        pkgs.curl
        pkgs.jq
        pkgs.nix-init
        pkgs.nix-update
        self.formatter.${pkgs.stdenv.hostPlatform.system}
      ];
    };
  });
}
