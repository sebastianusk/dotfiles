{ config, pkgs, walker, elephant, ... }:

{
  imports = [
    ../../modules/home/terminal
    ../../modules/home/desktop
    ../../modules/home/dev
    ../../modules/home/games.nix
    ../../modules/home/services/mcp.nix
    walker.homeManagerModules.default
  ];

  # Enable terminal environment
  modules.terminal.enable = true;

  # Enable gaming applications
  modules.games = {
    enable = true;
    retroarch = true;
    chiaki = true;
  };

  # Enable desktop environment (includes Wayland, apps, media, etc.)
  modules.desktop = {
    enable = true;

    # eww - status bar with widgets
    eww.enable = true;

    # GUI Applications
    apps = {
      enable = true;
      browsers = [ "firefox" ];
      defaultBrowser = "firefox";
      fileManager = "thunar";
      imageViewer = "imv";
      pdfViewer = "zathura";
      archiveManager = true;
      colorPicker = true;
    };

    # Media players and tools
    media = {
      enable = true;
      videoPlayer = "mpv";
      imageTools = true;
      screenRecording = true;
    };

    # System utilities
    systemUtils = {
      enable = true;
    };

    # Themes and appearance
    themes = {
      enable = true;
      gtkTheme = "catppuccin";
      iconTheme = "papirus";
      cursorTheme = "bibata";
    };
  };

  # Enable development tools
  modules.dev = {
    enable = true;
  };

  # MCP Service - Declarative MCP server configuration
  services.mcp = {
    enable = true;

    # Define MCP servers
    servers = {
      # Context7 - Enhanced context management
      context7 = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@upstash/context7-mcp" ];
      };

      # Brave Search - Web search capabilities
      brave-search = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
        env = {
          BRAVE_API_KEY = "\${BRAVE_API_KEY}";
        };
      };

      # Exa - Advanced web search
      exa = {
        type = "stdio";
        command = "npx";
        args = [ "-y" "exa-mcp-server" ];
        env = {
          EXA_API_KEY = "\${EXA_API_KEY}";
        };
      };

      # Filesystem - Access to local directories
      filesystem = {
        type = "stdio";
        command = "npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${config.home.homeDirectory}/Code"
          "${config.home.homeDirectory}/dotfiles"
        ];
      };
    };

    # Configure where MCP configs should be written
    targets = {
      claude = {
        enable = true;
        directory = "${config.home.homeDirectory}";
        fileName = ".claude.json";
        mergeMode = "deep";  # Safely merges with existing config
      };
    };

    # Install required packages
    packages = {
      nodejs = true;   # Required for npx-based servers
      python = false;  # Set to true if you use uvx-based servers
    };
  };

  # User packages
  home.packages = with pkgs; [
    claude-code
    elephant.packages.${pkgs.system}.default
  ];

  # Home Manager version
  home.stateVersion = "24.05";

  # Basic programs
  programs = {
    git = {
      enable = true;
      settings = {
        user = {
          name = "deck";
          email = "deck@steamdeck.local";
        };
      };
    };

    # Walker - Application Launcher (official module)
    walker = {
      enable = true;
      runAsService = true;

      # Walker configuration
      config = {
        search = {
          delay = 100;
          placeholder = "Search...";
        };
        list = {
          height = 400;
          always_show = true;
        };
        modules = [
          {
            name = "desktopapplications";
            prefix = "";
          }
          {
            name = "runner";
            prefix = "";
          }
          {
            name = "calc";
            prefix = "=";
          }
          {
            name = "finder";
            prefix = "/";
          }
        ];
      };
    };
  };
}
