# Nix Configuration

Multi-machine Nix configuration with modular structure.

## Directory Structure

- `modules/` - Reusable configuration modules for different functionality
- `hosts/` - Host-specific configurations
- `users/` - User-specific configurations and dotfiles

## Usage

Each host imports the modules it needs and can customize them with options.
