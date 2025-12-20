{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.mcp;

  # Server configuration type
  serverType = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "stdio" "http" "sse" ];
        default = "stdio";
        description = "MCP server transport type";
      };

      command = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Command to execute (for stdio servers)";
      };

      args = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Command arguments";
      };

      env = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Environment variables for the server";
      };

      url = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Server URL (for http/sse servers)";
      };

      headers = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "HTTP headers (for http/sse servers)";
      };
    };
  };

  # Target configuration type (where to write configs)
  targetType = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to generate configuration for this target";
      };

      directory = mkOption {
        type = types.str;
        description = "Directory where the config file lives";
      };

      fileName = mkOption {
        type = types.str;
        description = "Name of the configuration file";
      };

      mergeMode = mkOption {
        type = types.enum [ "replace" "deep" ];
        default = "deep";
        description = ''
          How to handle existing configuration:
          - replace: Overwrite entire file (dangerous!)
          - deep: Merge only the mcpServers section
        '';
      };
    };
  };

  # Generate MCP server configuration JSON
  mkServerConfig = name: server: {
    ${name} = {
      type = server.type;
    } // optionalAttrs (server.command != null) {
      command = server.command;
    } // optionalAttrs (server.args != []) {
      args = server.args;
    } // optionalAttrs (server.env != {}) {
      env = server.env;
    } // optionalAttrs (server.url != null) {
      url = server.url;
    } // optionalAttrs (server.headers != {}) {
      headers = server.headers;
    };
  };

  # Merge all enabled servers
  allServers = foldl' (acc: name:
    acc // (mkServerConfig name cfg.servers.${name})
  ) {} (attrNames cfg.servers);

  # Generate staged MCP configuration
  stagedConfig = {
    mcpServers = allServers;
  };

  # Script to merge configuration for a target
  mkMergeScript = target: pkgs.writeShellScript "merge-mcp-${target.fileName}" ''
    set -e

    TARGET_DIR="${target.directory}"
    TARGET_FILE="$TARGET_DIR/${target.fileName}"
    STAGED_FILE="${config.home.homeDirectory}/.mcp-generated/${target.fileName}"

    # Ensure target directory exists
    mkdir -p "$TARGET_DIR"

    # If target file doesn't exist, just copy staged config
    if [ ! -f "$TARGET_FILE" ]; then
      echo "Creating new MCP config: $TARGET_FILE"
      cp "$STAGED_FILE" "$TARGET_FILE"
      chmod 600 "$TARGET_FILE"
      exit 0
    fi

    ${if target.mergeMode == "replace" then ''
      # Replace mode: backup and overwrite
      echo "Replacing MCP config: $TARGET_FILE"
      cp "$TARGET_FILE" "$TARGET_FILE.backup-$(date +%Y%m%d-%H%M%S)"
      cp "$STAGED_FILE" "$TARGET_FILE"
      chmod 600 "$TARGET_FILE"
    '' else ''
      # Deep merge mode: only update mcpServers section
      echo "Merging MCP servers into: $TARGET_FILE"

      # Backup original
      cp "$TARGET_FILE" "$TARGET_FILE.backup-$(date +%Y%m%d-%H%M%S)"

      # Merge: existing config + new mcpServers
      ${pkgs.jq}/bin/jq -s '
        .[0] as $existing |
        .[1] as $staged |
        $existing |
        .mcpServers = ($staged.mcpServers)
      ' "$TARGET_FILE" "$STAGED_FILE" > "$TARGET_FILE.tmp"

      mv "$TARGET_FILE.tmp" "$TARGET_FILE"
      chmod 600 "$TARGET_FILE"

      echo "✓ MCP servers merged successfully"
    ''}
  '';

in
{
  options.services.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) service";

    servers = mkOption {
      type = types.attrsOf serverType;
      default = {};
      description = "MCP servers to configure";
      example = literalExpression ''
        {
          filesystem = {
            type = "stdio";
            command = "npx";
            args = [ "-y" "@modelcontextprotocol/server-filesystem" "/path/to/dir" ];
          };
          brave-search = {
            type = "stdio";
            command = "npx";
            args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
            env = {
              BRAVE_API_KEY = "\${BRAVE_API_KEY}";
            };
          };
        }
      '';
    };

    targets = mkOption {
      type = types.attrsOf targetType;
      default = {
        claude = {
          enable = true;
          directory = "${config.home.homeDirectory}";
          fileName = ".claude.json";
          mergeMode = "deep";
        };
      };
      description = "Target applications to configure";
      example = literalExpression ''
        {
          claude = {
            enable = true;
            directory = "\${config.home.homeDirectory}";
            fileName = ".claude.json";
            mergeMode = "deep";
          };
          cursor = {
            enable = true;
            directory = "\${config.home.homeDirectory}/.cursor";
            fileName = "mcp.json";
            mergeMode = "replace";
          };
        }
      '';
    };

    packages = {
      nodejs = mkOption {
        type = types.bool;
        default = true;
        description = "Install Node.js (required for npx-based MCP servers)";
      };

      python = mkOption {
        type = types.bool;
        default = false;
        description = "Install Python and uv (required for uvx-based MCP servers)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Install required packages
    home.packages = with pkgs; [
      jq  # Required for config merging
    ] ++ optional cfg.packages.nodejs nodejs
      ++ optionals cfg.packages.python [ python3 uv ];

    # Generate staged MCP configuration files
    home.file = listToAttrs (map (targetName:
      let
        target = cfg.targets.${targetName};
      in {
        name = ".mcp-generated/${target.fileName}";
        value = mkIf target.enable {
          text = builtins.toJSON stagedConfig;
          onChange = ''
            # Run merge script when staged config changes
            ${pkgs.bash}/bin/bash ${mkMergeScript target}
          '';
        };
      }
    ) (attrNames (filterAttrs (n: v: v.enable) cfg.targets)));

    # Activation script to perform initial setup
    home.activation.mcpServiceSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
      # Print status message
      echo "🔧 MCP Service: ${toString (length (attrNames cfg.servers))} servers configured"

      ${concatStringsSep "\n" (map (targetName:
        let
          target = cfg.targets.${targetName};
        in
        optionalString target.enable ''
          # Merge configuration for ${targetName}
          ${pkgs.bash}/bin/bash ${mkMergeScript target}
        ''
      ) (attrNames cfg.targets))}
    '';
  };
}
