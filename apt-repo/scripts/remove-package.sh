#!/usr/bin/env bash
# remove-package.sh
# Removes a package from the aptly repository.
#
# Usage: ./remove-package.sh <codename> <package-name> [version]
# If version is omitted, all versions are removed.

set -euo pipefail

CODENAME="${1:?usage: remove-package.sh <codename> <package-name> [version]}"
PACKAGE="${2:?usage: remove-package.sh <codename> <package-name> [version]}"
VERSION="${3:-}"

REPO_NAME="goldfang-${CODENAME}"

if [ -n "${VERSION}" ]; then
  echo "==> removing ${PACKAGE} (= ${VERSION}) from ${REPO_NAME}"
  aptly repo remove "${REPO_NAME}" "${PACKAGE} (= ${VERSION})"
else
  echo "==> removing all versions of ${PACKAGE} from ${REPO_NAME}"
  aptly repo remove "${REPO_NAME}" "${PACKAGE}"
fi

echo "==> done. re-publish to deploy changes."
