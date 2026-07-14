#!/usr/bin/env bash
# init-repo.sh
# Initializes the aptly repository for a given codename.
# Run once before adding any packages.

set -euo pipefail

CODENAME="${1:?usage: init-repo.sh <codename>}"
REPO_NAME="goldfang-${CODENAME}"

echo "==> initializing aptly repo for ${CODENAME}"

aptly repo show "${REPO_NAME}" 2>/dev/null && {
  echo "repo ${REPO_NAME} already exists"
  exit 0
}

aptly repo create \
  -distribution="${CODENAME}" \
  -component="main" \
  -architectures="amd64,arm64" \
  "${REPO_NAME}"

echo "==> created repo ${REPO_NAME}"
