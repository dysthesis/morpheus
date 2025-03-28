{
  self,
  stdenv,
  git,
  zig,
  ...
}:
stdenv.mkDerivation {
  pname = "morpheus";
  version = "0.1.0";

  src = self;

  nativeBuildInputs = [
    git
    zig
  ];

  buildPhase = ''
    mkdir -p .cache
    export XDG_CACHE_HOME=$PWD/.cache
    zig build
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp zig-out/bin/* $out/bin
  '';

  doCheck = true;
  checkPhase = ''
    zig build test
  '';

  dontConfigure = true;

  meta = {
    description = "A Minecraft server";
    mainProgram = "morpheus";
  };
}
