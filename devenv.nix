{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/basics/
  # env.GREET = "Welcome to Qwen Studio development!";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    # Rust dependencies
    pkg-config
    openssl
    
    # Tauri / GTK dependencies
    atk
    at-spi2-atk
    cairo
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    librsvg
    libsoup_3
    pango
    webkitgtk_4_1
    libappindicator-gtk3
    
    # Node.js
    nodejs_22
    nodePackages.npm
    
    # Utilities
    patchelf
  ];

  # https://devenv.sh/languages/
  languages.rust = {
    enable = true;
    channel = "stable";
    components = [ "rustc" "cargo" "clippy" "rustfmt" "rust-analyzer" ];
  };

  # Set environment variables for Tauri/WebKitGTK on Linux
  env = {
    WEBKIT_DISABLE_COMPOSITING_MODE = "1";
    WEBKIT_DISABLE_DMABUF_RENDERER = "1";
    GDK_BACKEND = "x11";
  };

  # Pre-commit hooks
  # pre-commit.hooks.rustfmt.enable = true;
  # pre-commit.hooks.clippy.enable = true;

  # https://devenv.sh/processes/
  # processes.ping.exec = "ping tauri.app";

  # See full reference at https://devenv.sh/reference/options/
}
