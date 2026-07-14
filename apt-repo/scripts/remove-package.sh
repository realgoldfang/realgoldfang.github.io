#!/usr/bin/env bash
# remove-package.sh
# Removes a package from the aptly repository.
#
# Usage: ./remove-package.sh <codename> <package-name> <version>
# Example: ./remove-package.sh noble mcp-sysd 1.0.0

set -euo pipefail

CODENAME="${1:?usage: remove-package.sh <codename> <package-name> <version>}"
PACKAGE="${2:?usage: remove-package.sh <codename> <package-name> <version>}"
VERSION="${3:?usage: remove-package.sh <codename> <package-name> <version>}"

REPO_NAME="goldfang-${CODENAME}"

echo "==> removing ${PACKAGE}_${VERSION} from ${REPO_NAME}"

aptly repo remove "${REPO_NAME}" "${PACKAGE} (= ${VERSION})"

echo "==> republishing ${CODENAME}"
aptly publish update \
  -batch \
  -gpg-key="goldfang-apt-repo <apt@realgoldfang.dev>" \
  "${CODENAME}" filesystem:nginx-repo

echo "==> done"
