{
  self,
  pkgs,
  lib,
  inputs,
  ...
}: rec {
  default = morpheus;
  morpheus = pkgs.callPackage ./morpheus.nix {inherit pkgs inputs lib self;};
}
