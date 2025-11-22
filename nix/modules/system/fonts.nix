{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.fonts;
in
{
  options.modules.system.fonts = {
    enable = mkEnableOption "system fonts including Nerd Fonts for terminal icons";

    nerdfonts = {
      jetbrainsMono = mkOption {
        type = types.bool;
        default = true;
        description = "Install JetBrainsMono Nerd Font (recommended for coding)";
      };

      firaCode = mkOption {
        type = types.bool;
        default = true;
        description = "Install FiraCode Nerd Font (popular coding font with ligatures)";
      };

      hack = mkOption {
        type = types.bool;
        default = false;
        description = "Install Hack Nerd Font";
      };

      meslo = mkOption {
        type = types.bool;
        default = false;
        description = "Install MesloLG Nerd Font (recommended for Powerlevel10k)";
      };

      sourceCodePro = mkOption {
        type = types.bool;
        default = false;
        description = "Install Source Code Pro Nerd Font";
      };
    };

    enableDefaultPackages = mkOption {
      type = types.bool;
      default = true;
      description = "Enable NixOS default font packages (DejaVu, Liberation, etc.)";
    };
  };

  config = mkIf cfg.enable {
    # Enable font configuration
    fonts = {
      # Enable fontconfig for better font rendering
      fontconfig.enable = true;

      # Enable default fonts (DejaVu, Liberation, etc.)
      enableDefaultPackages = cfg.enableDefaultPackages;

      # Install selected Nerd Fonts
      packages = [
        # Nerd Fonts provide icons/glyphs used by terminal apps, nvim, waybar, etc.
        (mkIf cfg.nerdfonts.jetbrainsMono pkgs.nerd-fonts.jetbrains-mono)
        (mkIf cfg.nerdfonts.firaCode pkgs.nerd-fonts.fira-code)
        (mkIf cfg.nerdfonts.hack pkgs.nerd-fonts.hack)
        (mkIf cfg.nerdfonts.meslo pkgs.nerd-fonts.meslo-lg)
        (mkIf cfg.nerdfonts.sourceCodePro pkgs.nerd-fonts.sauce-code-pro)

        # Additional useful fonts for fallback
        pkgs.noto-fonts
        pkgs.noto-fonts-cjk-sans
        pkgs.noto-fonts-color-emoji
      ];
    };
  };
}
