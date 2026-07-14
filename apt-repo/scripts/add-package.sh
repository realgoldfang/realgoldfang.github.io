#!/usr/bin/env bash
# add-package.sh
# Adds a .deb package to the aptly repository.
#
# Usage: ./add-package.sh <codename> <path-to-deb>
# Example: ./add-package.sh noble ./mcp-sysd_1.0.0_amd64.deb

set -euo pipefail

CODENAME="${1:?usage: add-package.sh <codename> <deb-path>}"
DEB_PATH="${2:?usage: add-package.sh <codename> <deb-path>}"

if [ ! -f "${DEB_PATH}" ]; then
  echo "error: ${DEB_PATH} not found"
  exit 1
fi

REPO_NAME="goldfang-${CODENAME}"

echo "==> adding $(basename ${DEB_PATH}) to ${REPO_NAME}"

aptly repo add "${REPO_NAME}" "${DEB_PATH}"

echo "==> package added. repo contents:"
aptly repo show -with-packages "${REPO_NAME}"
