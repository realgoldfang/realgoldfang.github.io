#!/usr/bin/env bash
# rotate-key.sh
# Rotates the GPG signing key for the apt repository.
#
# Run locally or in CI. After rotation, update the GitHub Actions secret
# with the new private key.

set -euo pipefail

OLD_KEY="goldfang-apt-repo"
TIMESTAMP=$(date +%Y%m%d)
NEW_KEY_NAME="goldfang-apt-repo-${TIMESTAMP}"
KEY_EMAIL="apt@realgoldfang.dev"

echo "==> rotating apt signing key"
echo "old key: ${OLD_KEY}"
echo "new key: ${NEW_KEY_NAME}"
echo ""

# Generate new key
gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${NEW_KEY_NAME}
Name-Email: ${KEY_EMAIL}
Expire-Date: 2y
%commit
EOF

echo "==> new key fingerprint:"
gpg --list-keys --keyid-format long "${NEW_KEY_NAME}"

echo ""
echo "==> export the new private key for GitHub Actions secret:"
echo "  gpg --export-secret-keys '${NEW_KEY_NAME} <${KEY_EMAIL}>' | base64"
echo ""
echo "==> update the APTLY_GPG_KEY secret in your repo settings"
echo "==> update the public key in site/public/apt/pubkey.gpg:"
echo "  gpg --export --armor '${NEW_KEY_NAME} <${KEY_EMAIL}>' > site/public/apt/pubkey.gpg"
echo ""
echo "==> clients must re-add the key after rotation:"
echo "  curl -fsSL https://realgoldfang.github.io/apt/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/goldfang.gpg"
