#!/usr/bin/env bash
# publish-repo.sh
# Signs and publishes all aptly repos to the nginx web root.
#
# Run this after adding packages. On CI, this can be triggered via SSH.

set -euo pipefail

KEY_NAME="goldfang-apt-repo"
KEY_EMAIL="apt@realgoldfang.dev"
KEYRING="/etc/apt/repo-signing-key.gpg"

echo "==> publishing all repos"

# For each codename, create the endpoint if needed and publish
for CODENAME in noble plucky; do
  REPO_NAME="goldfang-${CODENAME}"

  # Skip if repo doesn't exist yet
  aptly repo show "${REPO_NAME}" 2>/dev/null || continue

  # Create publish endpoint if it doesn't exist
  aptly publish list -raw | grep -q "filesystem:nginx-repo.*${CODENAME}" || \
    aptly publish repo \
      -batch \
      -gpg-key="${KEY_NAME} <${KEY_EMAIL}>" \
      -distribution="${CODENAME}" \
      -component="main" \
      "${REPO_NAME}" filesystem:nginx-repo

  echo "==> updating publish for ${CODENAME}"
  aptly publish update \
    -batch \
    -gpg-key="${KEY_NAME} <${KEY_EMAIL}>" \
    "${CODENAME}" filesystem:nginx-repo
done

echo "==> done. repo updated at https://apt.realgoldfang.dev/"
