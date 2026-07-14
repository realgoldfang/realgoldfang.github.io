#!/usr/bin/env bash
# add-package.sh
# Adds a .deb package to the aptly repository.
#
# Usage: ./add-package.sh <codename> <path-to-deb>
# Example: ./add-package.sh noble ./mcp-sysd_1.0.0_amd64.deb
#
# Codenames: noble (24.04), plucky (26.04)

set -euo pipefail

CODENAME="${1:?usage: add-package.sh <codename> <deb-path>}"
DEB_PATH="${2:?usage: add-package.sh <codename> <deb-path>}"

if [[ ! -f "${DEB_PATH}" ]]; then
  echo "error: ${DEB_PATH} not found"
  exit 1
fi

REPO_NAME="goldfang-${CODENAME}"

echo "==> adding ${DEB_PATH} to ${REPO_NAME}"

# Create repo if it doesn't exist
aptly repo show "${REPO_NAME}" 2>/dev/null || \
  aptly repo create -distribution="${CODENAME}" -component="main" "${REPO_NAME}"

# Add the package
aptly repo add "${REPO_NAME}" "${DEB_PATH}"

echo "==> published repos:"
aptly publish list

echo ""
echo "==> to publish/update, run:"
echo "  aptly publish update -batch \"${CODENAME}\" filesystem:nginx-repo"
