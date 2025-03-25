{
  self,
  stdenv,
  git,
  ...
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "morpheus";
  version = "0.1.0";

  src = self;

  nativeBuildInputs = [
    git
  ];

  zigBuildFlags = "";

  buildInputs = [
  ];

  dontConfigure = true;

  meta = {
    description = "A Minecraft server";
    mainProgram = "morpheus";
  };
})
