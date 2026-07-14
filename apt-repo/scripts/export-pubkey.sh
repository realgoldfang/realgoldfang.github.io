#!/usr/bin/env bash
# export-pubkey.sh
# Exports the GPG public key for the apt repo.
# This file gets committed to the repo (it's public by design).

set -euo pipefail

KEY_NAME="goldfang-apt-repo"
KEY_EMAIL="apt@realgoldfang.dev"
OUTPUT="${1:-/home/goldfang/projects/realgoldfang.github.io/site/public/apt/pubkey.gpg}"

mkdir -p "$(dirname "${OUTPUT}")"

echo "==> exporting public key to ${OUTPUT}"
gpg --export --armor "${KEY_NAME} <${KEY_EMAIL}>" > "${OUTPUT}"

echo "==> done. key available at https://realgoldfang.github.io/apt/pubkey.gpg"
