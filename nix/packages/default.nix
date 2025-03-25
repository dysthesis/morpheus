{ self, pkgs, ... }:
let
  inherit (pkgs) callPackage;
in
rec {
  morpheus = callPackage ./morpheus.nix { inherit self; };
  default = morpheus;
}
