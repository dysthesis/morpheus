pkgs:
pkgs.mkShell {
  name = "Poincare";
  packages = with pkgs; [
    nixd
    alejandra
    statix
    deadnix
    npins
    cargo
    rust-analyzer
    rustToolchains.nightly
  ];
}
