# Hosts

Host-specific configurations for different machines.

Each host directory should contain:
- `configuration.nix` - System-level configuration
- `hardware.nix` - Hardware-specific configuration
- `default.nix` - Main host configuration that imports modules

Hosts import modules from `../modules/` and can customize them with options.
