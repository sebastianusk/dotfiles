{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.desktop.media;
in
{
  options.modules.desktop.media = {
    enable = mkEnableOption "media players and tools";

    videoPlayer = mkOption {
      type = types.enum [ "mpv" "vlc" "both" "none" ];
      default = "mpv";
      description = "Video player to install";
    };

    imageTools = mkOption {
      type = types.bool;
      default = true;
      description = "Install image manipulation tools (imagemagick, gimp)";
    };

    screenRecording = mkOption {
      type = types.bool;
      default = true;
      description = "Install screen recording tools (wf-recorder, obs-studio)";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Video players
      (mkIf (cfg.videoPlayer == "mpv" || cfg.videoPlayer == "both") mpv)
      (mkIf (cfg.videoPlayer == "vlc" || cfg.videoPlayer == "both") vlc)

      # Image tools
      (mkIf cfg.imageTools imagemagick)
      (mkIf cfg.imageTools gimp)

      # Screen recording
      (mkIf cfg.screenRecording wf-recorder)
      (mkIf cfg.screenRecording obs-studio)
    ];

    # MPV configuration
    programs.mpv = mkIf (cfg.videoPlayer == "mpv" || cfg.videoPlayer == "both") {
      enable = true;
      config = {
        profile = "gpu-hq";
        vo = "gpu";
        hwdec = "auto";
        # Steam Deck specific: enable game mode compatibility
        x11-bypass-compositor = "no";
      };
    };
  };
}
