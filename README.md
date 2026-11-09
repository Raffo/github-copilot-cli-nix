# github-copilot-cli-nix

Nix package for the [GitHub Copilot CLI](https://github.com/github/copilot-cli) — always tracking the latest release.

The official [nixpkgs package](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/gi/github-copilot-cli) often lags behind. This repo stays up to date via automated checks every 6 hours.

No flakes required — uses stable Nix features only.

## Packaging

This package runs the platform-specific JavaScript distribution with Nix's Node.js,
rather than rewriting the standalone executable. The pinned `patchelf` workaround
for the standalone executable is no longer needed. Linux native addons still use
the standard `autoPatchelfHook`, with Nix's OpenSSL available at runtime.

Automatic CLI self-updates are disabled; update through Nix instead. The wrapper
preserves an existing `SSL_CERT_DIR` and otherwise uses `/etc/ssl/certs` on Linux,
including NixOS-managed certificates, or Nix's CA bundle on macOS. It does not
disable TLS verification.

As in nixpkgs, optional GUI, screen-capture, and local-inference dependencies are
not bundled. Features that require those libraries may be unavailable.

## Install

```bash
# Clone this repo
git clone https://github.com/Raffo/github-copilot-cli-nix.git
cd github-copilot-cli-nix

# Build
nix-build

# Install into your profile
nix-env -if .
```

## Use as an overlay

Add the overlay to your NixOS configuration or home-manager:

```nix
# configuration.nix or home.nix
{
  nixpkgs.overlays = [
    (import /path/to/github-copilot-cli-nix/overlay.nix)
  ];
}
```

Then use `pkgs.github-copilot-cli` anywhere in your config:

```nix
environment.systemPackages = [ pkgs.github-copilot-cli ];
```

Or with a remote tarball (no local clone needed):

```nix
nixpkgs.overlays = [
  (import (builtins.fetchTarball "https://github.com/Raffo/github-copilot-cli-nix/archive/main.tar.gz") + "/overlay.nix")
];
```

## Update manually

```bash
bash update.sh
```

## Supported platforms

- `x86_64-linux`
- `aarch64-linux`
- `x86_64-darwin`
- `aarch64-darwin`

## Auto-update

A GitHub Actions workflow runs every 6 hours, checks for new releases, and straights update main with the new version. Security wise, this assumes that the github releases are trusted. If you don't trust the upstream, don't use this project either. 
