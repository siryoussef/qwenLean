{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  wrapGAppsHook3,
  webkitgtk_4_1,
  openssl,
  glib-networking,
  libappindicator-gtk3,
  libayatana-appindicator,
  cargo-tauri,
  nodejs,
  npmHooks,
  fetchNpmDeps,
}:
rustPlatform.buildRustPackage (finalAttrs: {
    pname = "qwen-studio";
    version = "2.2.3";

    src = lib.cleanSource ./..;

    cargoHash = "sha256-NdcHOxjbDnU8EO0gZe5ALjMdjeok1PhJjct5+3JiUWU=";

    # Integration tests require node and network access for npx
    doCheck = false;

    # Point to the directory containing Cargo.toml
    cargoRoot = ".";

    # Build + test in the same directory
    buildAndTestSubdir = finalAttrs.cargoRoot;

    # --- Frontend (npm) ---
    npmDeps = fetchNpmDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-axurV2XXPB/SqtaSSBB8/KbhK8SrvZNgoejWw2SO4Nc=";
    };

    nativeBuildInputs = [
      cargo-tauri.hook
      nodejs
      npmHooks.npmConfigHook
      pkg-config
      wrapGAppsHook3
    ];

    buildInputs = [
      openssl
      glib-networking
      webkitgtk_4_1
      libappindicator-gtk3
      libayatana-appindicator
    ];

    postPatch = ''
    # Patch the hardcoded path to mcp-bridge.mjs to allow override via environment variable
    substituteInPlace src/mcp.rs \
      --replace-fail \
      'let bridge_path = concat!(env!("CARGO_MANIFEST_DIR"), "/mcp-bridge.mjs");' \
      'let bridge_path = std::env::var("QWEN_STUDIO_BRIDGE_PATH").unwrap_or_else(|_| concat!(env!("CARGO_MANIFEST_DIR"), "/mcp-bridge.mjs").to_string());'

    # Disable the updater and its artifact generation to avoid signing errors during bundling.
    # We also wipe the pubkey to be extra sure.
    substituteInPlace tauri.conf.json \
      --replace-fail '"active": true' '"active": false' \
      --replace-fail '"createUpdaterArtifacts": true' '"createUpdaterArtifacts": false' \
      --replace-fail '"pubkey": "dW50cnVzdGVkIGNvbW1lbnQ6IG1pbmlzaWduIHB1YmxpYyBrZXk6IDQwMjUwRjE1QjI1QkMzQjAKUldTQk9uUjVlYXN5eE5aY3BkOFdKc0h2TmR6Z3l0TlVjNkFjVHdGZ1hJbXl0Zm5mTjBvMjJqS3M="' '"pubkey": ""'
  '';

  preBuild = ''
    # Tauri requires a frontendDist directory to exist, even if empty
    mkdir -p dist
  '';

  # Add makeBinaryWrapper to nativeBuildInputs
  # and use it to wrap the binary
  postInstall = ''
    # Install bridge scripts and dependencies to a shared location
    mkdir -p $out/share/qwen-studio
    cp mcp-bridge.mjs $out/share/qwen-studio/
    cp mcp-proxy-server.js $out/share/qwen-studio/
    cp -r node_modules $out/share/qwen-studio/

    # Patch the interpreter in the bridge script
    substituteInPlace $out/share/qwen-studio/mcp-bridge.mjs \
      --replace-fail "/usr/bin/env node" "${nodejs}/bin/node"

    # Wrap the binary to set the bridge path and ensure node is in PATH.
    # We also add the library path for appindicator which is loaded via dlopen.
    wrapProgram $out/bin/qwen-studio \
      --set QWEN_STUDIO_BRIDGE_PATH "$out/share/qwen-studio/mcp-bridge.mjs" \
      --prefix PATH : "${lib.makeBinPath [ nodejs ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libayatana-appindicator libappindicator-gtk3 ]}"
  '';

    meta = {
      description = "Open-source Qwen AI desktop client with MCP support";
      homepage = "https://github.com/youssefvdel/qwen-studio";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "qwen-studio";
    };
  })
