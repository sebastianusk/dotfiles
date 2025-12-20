{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.dev;
in
{
  imports = [
    ./mcp.nix
  ];

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
