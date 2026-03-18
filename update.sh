#!/usr/bin/env bash
# Updates sources.json to the latest github/copilot-cli release.
# Requires: curl, jq, sha256sum, xxd, base64
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_FILE="$ROOT/sources.json"

LATEST_TAG=$(curl -s https://api.github.com/repos/github/copilot-cli/releases/latest | jq -r .tag_name)

if [ -z "$LATEST_TAG" ] || [ "$LATEST_TAG" = "null" ]; then
  echo "Failed to fetch latest release from GitHub API"
  exit 1
fi

VERSION="${LATEST_TAG#v}"
CURRENT_VERSION=$(jq -r .version "$SOURCES_FILE" 2>/dev/null || echo "unknown")

if [ "$VERSION" = "$CURRENT_VERSION" ]; then
  echo "Already up to date: v${VERSION}"
  exit 0
fi

echo "Updating from v${CURRENT_VERSION} to v${VERSION}"

TMP_FILE=$(mktemp)
trap 'rm -f "$TMP_FILE" "${TMP_FILE}.tmp"' EXIT

jq -n --arg v "$VERSION" '{version: $v}' > "$TMP_FILE"

process_platform() {
  local system="$1"
  local name="$2"
  local url="https://github.com/github/copilot-cli/releases/download/v${VERSION}/${name}.tar.gz"

  echo "  Fetching $system ($name)..."

  local sha256_hex
  sha256_hex=$(curl -sL "$url" | sha256sum | awk '{print $1}')
  local sri_hash="sha256-$(printf '%s' "$sha256_hex" | xxd -r -p | base64 -w0)="

  jq --arg sys "$system" --arg n "$name" --arg h "$sri_hash" \
    '. + {($sys): {name: $n, hash: $h}}' "$TMP_FILE" > "${TMP_FILE}.tmp" \
    && mv "${TMP_FILE}.tmp" "$TMP_FILE"
}

process_platform "x86_64-linux"   "copilot-linux-x64"
process_platform "aarch64-linux"  "copilot-linux-arm64"
process_platform "x86_64-darwin"  "copilot-darwin-x64"
process_platform "aarch64-darwin" "copilot-darwin-arm64"

mv "$TMP_FILE" "$SOURCES_FILE"
trap - EXIT

echo "Updated sources.json to v${VERSION}"
