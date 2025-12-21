{ config, lib, pkgs, ... }:

#
# Eww (ElKowar's Wacky Widgets) - Desktop bar/widget system
#
# This module configures eww as a Wayland status bar with:
# - Automatic multi-monitor detection and spawning
# - Hyprland workspace integration
# - System info widgets (CPU, RAM)
# - Customizable appearance (colors, styling)
#
# Architecture:
# - Single window definition in yuck config
# - Startup script detects monitors via hyprctl
# - Opens bar on each monitor with unique ID
# - Scripts for workspace tracking and system info
#
# Usage:
#   modules.desktop.eww.enable = true;
#
# Customize colors:
#   modules.desktop.eww.appearance.primaryColor = "#7aa2f7";
#

with lib;

let
  cfg = config.modules.desktop.eww;

  # Helper scripts for system info
  cpuScript = pkgs.writeShellScript "eww-cpu" ''
    #!/usr/bin/env bash
    ${pkgs.procps}/bin/top -bn1 | ${pkgs.gnugrep}/bin/grep "Cpu(s)" | ${pkgs.gnused}/bin/sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | ${pkgs.gawk}/bin/awk '{print 100 - $1}'
  '';

  memScript = pkgs.writeShellScript "eww-mem" ''
    #!/usr/bin/env bash
    ${pkgs.procps}/bin/free -m | ${pkgs.gawk}/bin/awk 'NR==2{printf "%.0f", $3*100/$2 }'
  '';

  # Hyprland workspace scripts
  workspacesScript = pkgs.writeShellScript "eww-workspaces" ''
    #!/usr/bin/env bash

    spaces() {
      WORKSPACE_WINDOWS=$(${pkgs.hyprland}/bin/hyprctl workspaces -j | ${pkgs.jq}/bin/jq 'map({key: .id | tostring, value: .windows}) | from_entries')
      seq 1 10 | ${pkgs.jq}/bin/jq --argjson windows "$WORKSPACE_WINDOWS" --slurp -Mc 'map(tostring) | map({id: ., windows: ($windows[.] // 0)})'
    }

    spaces
    ${pkgs.socat}/bin/socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
      spaces
    done
  '';

  activeWorkspaceScript = pkgs.writeShellScript "eww-active-workspace" ''
    #!/usr/bin/env bash

    ${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq --raw-output .[0].activeWorkspace.id
    ${pkgs.socat}/bin/socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - |
      ${pkgs.gnugrep}/bin/grep '^workspace>>' |
      ${pkgs.gnused}/bin/sed 's/^workspace>>//'
  '';

  # Active window title script
  activeWindowScript = pkgs.writeShellScript "eww-active-window" ''
    #!/usr/bin/env bash

    get_window() {
      ${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq --raw-output '.title // "Desktop"'
    }

    get_window
    ${pkgs.socat}/bin/socat -u UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock - | while read -r line; do
      get_window
    done
  '';

  # Time and date script
  timeScript = pkgs.writeShellScript "eww-time" ''
    #!/usr/bin/env bash
    date '+%H:%M'
  '';

  dateScript = pkgs.writeShellScript "eww-date" ''
    #!/usr/bin/env bash
    date '+%a, %b %d'
  '';

  # Startup script that automatically detects monitors and opens eww on each
  startupScript = pkgs.writeShellScript "eww-startup" ''
    #!/usr/bin/env bash

    # Wait a bit for Hyprland to fully initialize
    sleep 1

    # Get all monitor IDs and open eww bar on each
    ${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].id' | while read -r monitor_id; do
      ${cfg.package}/bin/eww open bar --screen "$monitor_id" --id "bar-$monitor_id"
    done
  '';

  # Eww configuration files
  ewwYuck = pkgs.writeText "eww.yuck" ''
    ;; Variables
    (deflisten workspaces :initial "[]" "${workspacesScript}")
    (deflisten active_workspace :initial "1" "${activeWorkspaceScript}")
    (deflisten active_window :initial "Desktop" "${activeWindowScript}")
    (defpoll cpu :interval "2s" "${cpuScript}")
    (defpoll mem :interval "2s" "${memScript}")
    (defpoll time :interval "1s" "${timeScript}")
    (defpoll date :interval "10s" "${dateScript}")

    ;; Widgets
    (defwidget workspaces []
      (box :class "workspaces"
           :orientation "h"
           :space-evenly false
           :halign "start"
           :spacing 5
        (for workspace in workspaces
          (button :class "workspace ${"$"}{workspace.id == active_workspace ? 'active' : ""} ${"$"}{workspace.windows > 0 ? 'occupied' : 'empty'}"
                  :onclick "hyprctl dispatch workspace ${"$"}{workspace.id}"
                  :visible "${"$"}{workspace.windows > 0 || workspace.id == active_workspace}"
            "${"$"}{workspace.id}"))))

    (defwidget window_title []
      (box :class "window-title"
           :orientation "h"
           :space-evenly false
           :halign "center"
        (label :class "title"
               :text "${"$"}{active_window}"
               :limit-width 50)))

    (defwidget system_info []
      (box :class "system-info"
           :orientation "h"
           :space-evenly false
           :halign "end"
           :spacing 5
        (box :class "cpu"
          (label :text "󰻠 ${"$"}{round(cpu, 0)}%"))
        (box :class "mem"
          (label :text "󰍛 ${"$"}{mem}%"))
        (box :class "time"
          (label :text "󰥔 ${"$"}{time}"))
        (box :class "date"
          (label :text "󰸗 ${"$"}{date}"))))

    ;; Bar
    (defwidget bar []
      (centerbox :class "bar"
        (workspaces)
        (window_title)
        (system_info)))

    ;; Windows
    ;; Single window definition - can be opened on multiple monitors
    ;; using: eww open bar --screen N --id bar-N
    (defwindow bar
      :monitor 0
      :geometry (geometry :x "0%"
                          :y "0%"
                          :width "100%"
                          :height "32px"
                          :anchor "top center")
      :stacking "fg"
      :exclusive true
      :focusable false
      (bar))
  '';

  ewwScss = pkgs.writeText "eww.scss" ''
    * {
      all: unset;
      font-family: "JetBrains Mono", monospace;
      font-size: 14px;
    }

    .bar {
      background-color: ${cfg.appearance.backgroundColor};
      color: ${cfg.appearance.textColor};
      padding: 0 10px;
    }

    // Workspaces
    .workspaces {
      padding: 2px 5px;
    }

    .workspace {
      min-width: 25px;
      padding: 2px 8px;
      margin: 0 2px;
      border-radius: 5px;
      background-color: ${cfg.appearance.workspaceInactive};
      color: ${cfg.appearance.textColor};
      transition: all 0.3s ease;

      &.active {
        background-color: ${cfg.appearance.primaryColor};
        color: ${cfg.appearance.backgroundColor};
        font-weight: bold;
      }

      &.occupied:not(.active) {
        background-color: ${cfg.appearance.workspaceOccupied};
      }

      &:hover {
        background-color: ${cfg.appearance.primaryColor};
        opacity: 0.8;
      }
    }

    // Window Title
    .window-title {
      padding: 2px 10px;

      .title {
        color: ${cfg.appearance.textColor};
        font-weight: 500;
      }
    }

    // System Info
    .system-info {
      padding: 2px 5px;

      .cpu, .mem, .time, .date {
        padding: 4px 8px;
        border-radius: 5px;
        background-color: ${cfg.appearance.moduleBackground};

        label {
          color: ${cfg.appearance.textColor};
        }
      }
    }
  '';
in
{
  options.modules.desktop.eww = {
    enable = mkEnableOption "eww - ElKowar's Wacky Widgets for Wayland";

    package = mkOption {
      type = types.package;
      default = pkgs.eww;
      description = "eww package to use";
    };

    appearance = {
      backgroundColor = mkOption {
        type = types.str;
        default = "#1a1b26";
        description = "Bar background color";
      };

      textColor = mkOption {
        type = types.str;
        default = "#a9b1d6";
        description = "Text color";
      };

      primaryColor = mkOption {
        type = types.str;
        default = "#7aa2f7";
        description = "Primary accent color";
      };

      workspaceInactive = mkOption {
        type = types.str;
        default = "#24273a";
        description = "Inactive workspace background color";
      };

      workspaceOccupied = mkOption {
        type = types.str;
        default = "#414868";
        description = "Occupied workspace background color";
      };

      moduleBackground = mkOption {
        type = types.str;
        default = "#24273a";
        description = "Module background color";
      };
    };

    openOnStartup = mkOption {
      type = types.bool;
      default = true;
      description = "Open eww bar on Hyprland startup";
    };
  };

  config = mkIf cfg.enable {
    # Install eww
    home.packages = [ cfg.package ];

    # Create eww configuration directory
    home.file.".config/eww/eww.yuck".source = ewwYuck;
    home.file.".config/eww/eww.scss".source = ewwScss;

    # Auto-start eww bars on all monitors with Hyprland
    # The startup script automatically detects all connected monitors
    wayland.windowManager.hyprland.settings.exec-once = mkIf cfg.openOnStartup [
      "${startupScript}"
    ];
  };
}
