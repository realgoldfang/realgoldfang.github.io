#!/usr/bin/env bash
# publish.sh
# Signs and publishes all aptly repos to a local directory tree.
# The output is what gets deployed to GitHub Pages.
#
# Usage: ./publish.sh [output-dir]
# Default output: /tmp/aptly-publish

set -euo pipefail

KEY_NAME="goldfang-apt-repo"
KEY_EMAIL="apt@realgoldfang.dev"
OUTPUT_DIR="${1:-/tmp/aptly-publish}"

mkdir -p "${OUTPUT_DIR}"

echo "==> publishing repos to ${OUTPUT_DIR}"

for CODENAME in noble plucky; do
  REPO_NAME="goldfang-${CODENAME}"

  # Skip if repo doesn't exist
  aptly repo show "${REPO_NAME}" 2>/dev/null || continue

  # Check if already published
  if aptly publish list -raw | grep -q "^${CODENAME} "; then
    echo "==> updating ${CODENAME}"
    aptly publish update \
      -batch \
      -gpg-key="${KEY_NAME} <${KEY_EMAIL}>" \
      -distribution="${CODENAME}" \
      -architectures="amd64,arm64" \
      "${CODENAME}" "${OUTPUT_DIR}"
  else
    echo "==> publishing ${CODENAME} for the first time"
    aptly publish repo \
      -batch \
      -gpg-key="${KEY_NAME} <${KEY_EMAIL}>" \
      -distribution="${CODENAME}" \
      -component="main" \
      -architectures="amd64,arm64" \
      "${REPO_NAME}" "${OUTPUT_DIR}"
  fi
done

echo "==> published tree:"
find "${OUTPUT_DIR}" -type f | head -20
echo "..."
echo "==> done. deploy ${OUTPUT_DIR} to github pages"
