# Import this overlay into your NixOS configuration or home-manager:
#
#   nixpkgs.overlays = [ (import /path/to/this/overlay.nix) ];
#
# Then use `pkgs.github-copilot-cli` anywhere in your config.

final: prev: {
  github-copilot-cli = prev.callPackage ./default.nix { pkgs = prev; };
}
