{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.system.development;
in
{
  options.modules.system.development = {
    enable = mkEnableOption "base development tools and compilers";

    includeDebugTools = mkOption {
      type = types.bool;
      default = false;
      description = "Include gdb and other debugging tools";
    };

    includePythonBuildDeps = mkOption {
      type = types.bool;
      default = true;
      description = "Include Python build dependencies (zlib, libffi, openssl, readline)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # C/C++ Compilers
      gcc
      clang

      # Build tools
      gnumake
      cmake
      pkg-config
      binutils

      # Standard build environment
      stdenv.cc

      # Version control
      git-lfs

      # Build helpers
      autoconf
      automake
      libtool
      patch

      # Python build dependencies (needed for many LSPs and tools)
      (mkIf cfg.includePythonBuildDeps zlib)
      (mkIf cfg.includePythonBuildDeps libffi)
      (mkIf cfg.includePythonBuildDeps openssl)
      (mkIf cfg.includePythonBuildDeps readline)

      # Optional debug tools
      (mkIf cfg.includeDebugTools gdb)
      (mkIf cfg.includeDebugTools valgrind)
    ];

    # Ensure build tools are available system-wide
    environment.variables = {
      # Some tools look for cc instead of gcc
      CC = "${pkgs.gcc}/bin/gcc";
      CXX = "${pkgs.gcc}/bin/g++";
    };
  };
}
