{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.wayland;
in
{
  options.modules.wayland = {
    enable = mkEnableOption "Wayland desktop environment with Hyprland and essential tools";

    dotfilesPath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Path to dotfiles repository";
    };

    packages = {
      hyprland.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install and configure Hyprland window manager";
      };

      rofi.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install and configure Rofi application launcher";
      };

      waybar.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Waybar status bar";
      };

      dunst.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install Dunst notification daemon";
      };

      wl-clipboard.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install wl-clipboard for Wayland clipboard utilities";
      };

      grimblast.enable = mkOption {
        type = types.bool;
        default = true;
        description = "Install grimblast for screenshots";
      };
    };

    rofi = {
      theme = mkOption {
        type = types.str;
        default = "gruvbox-dark";
        description = "Rofi theme to use";
      };
    };
  };

  config = mkIf cfg.enable {
    # User packages - install packages without overly declarative config
    # since we may use dotfiles via symlinks for some
    home.packages = with pkgs; [
      (mkIf cfg.packages.rofi.enable rofi)
      (mkIf cfg.packages.rofi.enable rofi-power-menu)
      (mkIf cfg.packages.dunst.enable dunst)
      (mkIf cfg.packages.wl-clipboard.enable wl-clipboard)
      (mkIf cfg.packages.grimblast.enable grimblast)
      # Additional Wayland utilities
      (mkIf cfg.enable wlr-randr)
      (mkIf cfg.enable xdg-utils)
      (mkIf cfg.enable grim)
      (mkIf cfg.enable slurp)
    ];

    # Rofi declarative configuration
    programs.rofi = mkIf cfg.packages.rofi.enable {
      enable = true;
      theme = cfg.rofi.theme;
    };

    # Waybar declarative configuration
    programs.waybar = mkIf cfg.packages.waybar.enable {
      enable = true;
      systemd.enable = true;

      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;

          modules-left = [ "hyprland/workspaces" "hyprland/window" ];
          modules-center = [ "clock" ];
          modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];

          "hyprland/workspaces" = {
            disable-scroll = false;
            all-outputs = true;
            format = "{icon}";
            format-icons = {
              "1" = "1";
              "2" = "2";
              "3" = "3";
              "4" = "4";
              "5" = "5";
              "6" = "6";
              "7" = "7";
              "8" = "8";
              "9" = "9";
              "10" = "10";
            };
          };

          "hyprland/window" = {
            format = "{}";
            max-length = 50;
            separate-outputs = true;
          };

          clock = {
            format = "{:%a %b %d  %H:%M}";
            tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          };

          cpu = {
            format = " {usage}%";
            tooltip = false;
          };

          memory = {
            format = " {}%";
          };

          battery = {
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-icons = ["" "" "" "" ""];
          };

          network = {
            format-wifi = " {essid} ({signalStrength}%)";
            format-ethernet = " {ipaddr}/{cidr}";
            format-disconnected = "⚠ Disconnected";
            tooltip-format = "{ifname} via {gwaddr}";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}%";
            format-muted = " Muted";
            format-icons = {
              headphone = "";
              hands-free = "";
              headset = "";
              phone = "";
              portable = "";
              car = "";
              default = ["" "" ""];
            };
            on-click = "pavucontrol";
          };

          tray = {
            spacing = 10;
          };
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
          font-size: 13px;
          min-height: 0;
        }

        window#waybar {
          background-color: rgba(43, 48, 59, 0.9);
          color: #ffffff;
        }

        #workspaces button {
          padding: 0 8px;
          background-color: transparent;
          color: #ffffff;
          border-bottom: 2px solid transparent;
        }

        #workspaces button:hover {
          background: rgba(0, 0, 0, 0.2);
        }

        #workspaces button.active {
          background-color: #64727D;
          border-bottom: 2px solid #ffffff;
        }

        #workspaces button.urgent {
          background-color: #eb4d4b;
        }

        #window {
          margin: 0 8px;
          color: #64727D;
        }

        #clock,
        #battery,
        #cpu,
        #memory,
        #network,
        #pulseaudio,
        #tray {
          padding: 0 10px;
          margin: 0 4px;
          color: #ffffff;
        }

        #battery.charging {
          color: #26A65B;
        }

        #battery.warning:not(.charging) {
          color: #ffbe61;
        }

        #battery.critical:not(.charging) {
          color: #f53c3c;
        }

        #pulseaudio.muted {
          color: #a0a0a0;
        }

        #network.disconnected {
          color: #f53c3c;
        }
      '';
    };

    # Symlink configuration files from dotfiles if they exist
    home.file = mkMerge [
      # Hyprland config
      (mkIf cfg.packages.hyprland.enable {
        ".config/hypr" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/hypr";
        };
      })

      # Dunst config
      (mkIf cfg.packages.dunst.enable {
        ".config/dunst" = {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesPath}/config/dunst";
        };
      })
    ];

    # Wayland session variables
    home.sessionVariables = mkIf cfg.enable {
      # Wayland-specific environment variables
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      XDG_SESSION_TYPE = "wayland";
    };
  };
}
