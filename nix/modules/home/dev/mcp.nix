{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.dev.mcp;

  # Helper to create MCP server package with Node.js dependencies
  mkMcpServer = name: npmPackage: pkgs.writeShellScriptBin name ''
    ${pkgs.nodejs}/bin/npx -y ${npmPackage}
  '';
in
{
  options.modules.dev.mcp = {
    enable = mkEnableOption "MCP (Model Context Protocol) servers for Claude Code";

    servers = {
      context7 = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable context7 MCP server for enhanced context management";
        };
      };

      brave = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Brave MCP server for browser automation";
        };
      };

      exa = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable Exa MCP server for web search capabilities";
        };
      };
    };

    autoConfigureClaude = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically configure Claude Code with enabled MCP servers";
    };
  };

  config = mkIf cfg.enable {
    # Install Node.js (required for MCP servers)
    home.packages = with pkgs; [
      nodejs
      # MCP server wrappers
      (mkIf cfg.servers.context7.enable (mkMcpServer "mcp-context7" "@context7/mcp-server"))
      (mkIf cfg.servers.brave.enable (mkMcpServer "mcp-brave" "@modelcontextprotocol/server-brave-search"))
      (mkIf cfg.servers.exa.enable (mkMcpServer "mcp-exa" "@modelcontextprotocol/server-exa"))
    ];

    # Configure Claude Code MCP servers
    home.file.".config/claude/claude_desktop_config.json" = mkIf cfg.autoConfigureClaude {
      text = builtins.toJSON {
        mcpServers = {
          context7 = mkIf cfg.servers.context7.enable {
            command = "npx";
            args = [ "-y" "@context7/mcp-server" ];
          };
          brave-search = mkIf cfg.servers.brave.enable {
            command = "npx";
            args = [ "-y" "@modelcontextprotocol/server-brave-search" ];
            env = {
              BRAVE_API_KEY = "\${BRAVE_API_KEY}"; # User needs to set this
            };
          };
          exa = mkIf cfg.servers.exa.enable {
            command = "npx";
            args = [ "-y" "@modelcontextprotocol/server-exa" ];
            env = {
              EXA_API_KEY = "\${EXA_API_KEY}"; # User needs to set this
            };
          };
        };
      };
    };

    # Add activation script to remind user about API keys
    home.activation.mcpServerSetup = mkIf cfg.autoConfigureClaude (
      lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [[ ! -f "$HOME/.config/fish/secret.fish" ]]; then
          $DRY_RUN_CMD echo "⚠️  MCP servers enabled but secret.fish not found"
          $DRY_RUN_CMD echo "   Create ~/.config/fish/secret.fish with:"
          $DRY_RUN_CMD echo "   set -gx BRAVE_API_KEY 'your-brave-api-key'"
          $DRY_RUN_CMD echo "   set -gx EXA_API_KEY 'your-exa-api-key'"
        fi
      ''
    );
  };
}
