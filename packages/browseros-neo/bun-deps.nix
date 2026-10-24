{
  stdenvNoCC,
  bun,
  writableTmpDirAsHomeHook,
  source,
}:

# bun uses the isolated linker in workspaces: dependency symlinks live in
# per-package node_modules trees pointing into node_modules/.bun, so the
# whole workspace tree must be captured, not just the root node_modules.
stdenvNoCC.mkDerivation {
  pname = "browseros-neo-bun-deps";
  version = "0.51.1.2";
  src = "${source}/packages/browseros-agent";

  nativeBuildInputs = [
    bun
    writableTmpDirAsHomeHook
  ];

  dontConfigure = true;
  dontFixup = true;

  buildPhase = ''
    runHook preBuild
    export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
    bun install --frozen-lockfile --ignore-scripts --no-progress
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -a . "$out"
    runHook postInstall
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  outputHash = "sha256-gXZjseQPOZmaIr7H+6wsNJEEeNnCcqQUIKuYfOJHtkI=";
}
