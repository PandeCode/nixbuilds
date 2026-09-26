# `lib` and `system` come from the package set before this overlay, so the
# attribute names here never depend on the result of the overlay
{
  pkgs,
  lib,
  system,
  inputs,
}:

let
  # a package from another flake, if that flake builds for this system
  fromFlake =
    input: name: attr:
    lib.attrsets.optionalAttrs (input.packages ? ${system}) {
      ${name} = input.packages.${system}.${attr};
    };
in

lib.filesystem.packagesFromDirectoryRecursive {
  inherit (pkgs) callPackage;
  directory = ./by-name;
}
# keep-sorted start
// fromFlake inputs.boomer "boomer" "default"
// fromFlake inputs.nix-alien "nix-alien" "nix-alien"
// fromFlake inputs.zig-overlay "zig-master" "master"
# keep-sorted end
// {
  toolsets = import ./toolsets.nix { inherit pkgs; };
}
