{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.waybar;
in
{
  options.modules.desktop.waybar = {
    enable = mkEnableOption "Waybar status bar for Wayland";
  };

  config = mkIf cfg.enable {
    programs.waybar = {
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
          modules-right = [ "pulseaudio" "network" "bluetooth" "battery" ];

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

          battery = {
            bat = "BAT1";
            states = {
              warning = 30;
              critical = 15;
            };
            format = "{icon} {capacity}%";
            format-charging = "󰂄 {capacity}%";
            format-plugged = "󰚥 {capacity}%";
            format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
            tooltip-format = "{timeTo}, {capacity}%";
          };

          network = {
            format-wifi = "󰖩";
            format-ethernet = "󰈀";
            format-disconnected = "󰖪";
            tooltip-format = "{ifname}: {ipaddr}/{cidr}\n{essid} ({signalStrength}%)";
            on-click = "nm-connection-editor";
          };

          bluetooth = {
            format = "󰂯";
            format-connected = "󰂱 {num_connections}";
            format-disabled = "󰂲";
            tooltip-format = "{controller_alias}\t{controller_address}\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\t{controller_address}\n{num_connections} connected:\n{device_enumerate}";
            tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
            on-click = "blueman-manager";
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-bluetooth = "{icon} {volume}%";
            format-muted = "󰖁";
            format-icons = {
              default = ["󰕿" "󰖀" "󰕾"];
            };
            on-click = "pavucontrol";
          };
        };
      };

      style = ''
        * {
          border: none;
          border-radius: 0;
          font-family: "JetBrainsMono Nerd Font", monospace;
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

        #clock {
          padding: 0 10px;
          margin: 0 4px;
          background-color: #64727D;
          color: #ffffff;
        }

        /* Right side modules - same background as active workspace */
        #battery,
        #network,
        #bluetooth,
        #pulseaudio {
          padding: 0 10px;
          margin: 0 4px;
          background-color: #64727D;
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

        #bluetooth.disabled {
          color: #a0a0a0;
        }
      '';
    };
  };
}
