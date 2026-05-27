{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.qwen-studio;
in {
  options.programs.qwen-studio = {
    enable = mkEnableOption "Qwen Studio, an open-source Qwen AI desktop client";
    package = mkOption {
      type = types.package;
      default = pkgs.qwen-studio;
      description = "The package to use for Qwen Studio.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
