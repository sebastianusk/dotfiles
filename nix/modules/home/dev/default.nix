{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.dev;
in
{
  options.modules.dev = {
    enable = mkEnableOption "development tools and environments";
  };

  config = mkIf cfg.enable {
    # Common development tools
    home.packages = with pkgs; [
      git
      gh  # GitHub CLI
      jq
      yq-go
    ];
  };
}
