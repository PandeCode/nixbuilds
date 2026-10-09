# nixbuilds

Personal nixpkgs: packages that are not in nixpkgs, packages from other
flakes rebuilt against the same nixpkgs, and the editor toolsets. CI builds
everything and pushes it to the `charon` cache.

This flake holds the nixpkgs pin for my other repos. They follow it:

```nix
nixpkgs.follows = "nixbuilds/nixpkgs";
```

## Use

```nix
{
  nixpkgs.overlays = [ inputs.nixbuilds.overlays.default ];
  environment.systemPackages = [ pkgs.helium ];
}
```

or without the overlay:

```nix
inputs.nixbuilds.packages.${system}.helium
inputs.nixbuilds.legacyPackages.${system}.toolsets.profiles.full
```

## Add a package

Create `pkgs/by-name/<name>/package.nix`, written like a nixpkgs package.
The folder name is the attribute name. Nothing else to register.

```bash
nix develop
nix-init pkgs/by-name/<name>/package.nix
nix build .#<name>
```

## Update

`pkgs/update.sh` bumps every package that can find its own new version. A
workflow runs it with `nix flake update` every saturday, builds the result and
opens a pr. Run it by hand with:

```bash
nix develop --command pkgs/update.sh
```

A new package that should update itself gets a line in that script.

## Develop

```bash
nix fmt
nix flake check
```
