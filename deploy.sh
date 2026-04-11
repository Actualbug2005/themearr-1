#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

REPO="Themearr/themearr"

echo ">>> Starting Themearr Deployment..."

# 1. Ensure git is installed
apt-get update -qq
apt-get install -y curl tar -qq

# 2. Prepare a temporary source directory
SRC_DIR="/tmp/themearr_source"
if [ -d "$SRC_DIR" ]; then
    rm -rf "$SRC_DIR"
fi
mkdir -p "$SRC_DIR"

# 3. Download latest release source to the temporary zone
echo ">>> Resolving latest release..."
LATEST_JSON="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest")"
TAG="$(printf '%s' "$LATEST_JSON" | grep -oE '"tag_name"\s*:\s*"[^"]+"' | head -n1 | sed -E 's/.*"([^"]+)"/\1/')"
TARBALL_URL="$(printf '%s' "$LATEST_JSON" | grep -oE '"tarball_url"\s*:\s*"[^"]+"' | head -n1 | sed -E 's/.*"([^"]+)"/\1/')"

if [ -z "$TAG" ] || [ -z "$TARBALL_URL" ]; then
    echo ">>> Failed to resolve latest release metadata from GitHub"
    exit 1
fi

echo ">>> Downloading release ${TAG}..."
curl -fsSL "$TARBALL_URL" -o /tmp/themearr-release.tar.gz
tar -xzf /tmp/themearr-release.tar.gz -C "$SRC_DIR" --strip-components=1
printf '%s\n' "$TAG" > "$SRC_DIR/VERSION"

# 4. Safely wipe old application code (preserves database and .env)
echo ">>> Preparing target directory..."
rm -rf /opt/themearr/app
rm -f /opt/themearr/requirements.txt

# 5. Execute the native installation script
echo ">>> Executing native installer..."
cd "$SRC_DIR"
chmod +x install.sh
bash install.sh

# 6. Clean up temporary files
rm -rf "$SRC_DIR"
rm -f /tmp/themearr-release.tar.gz

echo ">>> Deployment Complete!"
echo ">>> Open the web UI to finish setup by signing in with Plex."
echo ">>> Then use the UI update flow whenever a new GitHub release is published."
