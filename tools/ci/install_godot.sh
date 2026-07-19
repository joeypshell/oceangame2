#!/usr/bin/env bash
set -euo pipefail

: "${GODOT_VERSION:?GODOT_VERSION must be set}"
: "${GODOT_STATUS:?GODOT_STATUS must be set}"

archive="Godot_v${GODOT_VERSION}-${GODOT_STATUS}_linux.x86_64.zip"
binary="Godot_v${GODOT_VERSION}-${GODOT_STATUS}_linux.x86_64"
release_url="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-${GODOT_STATUS}/${archive}"

sudo apt-get update
sudo apt-get install -y unzip
curl --fail --location --retry 3 --output godot.zip "${release_url}"
unzip -q godot.zip -d godot-bin
chmod +x "godot-bin/${binary}"
sudo mv "godot-bin/${binary}" /usr/local/bin/godot
godot --headless --version
