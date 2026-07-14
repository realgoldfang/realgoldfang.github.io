#!/usr/bin/env bash
# generate-repo-key.sh
# Generates a dedicated GPG key for signing the apt repository.
#
# Run this on the publishing server (EC2 recommended).
# Store the private key at /etc/apt/repo-signing-key.gpg (600 perms).
# The public key gets copied to the web root for download.

set -euo pipefail

KEY_NAME="goldfang-apt-repo"
KEY_EMAIL="apt@realgoldfang.dev"
KEY_EXPIRE="2y"
KEYRING="/etc/apt/repo-signing-key.gpg"
PUBKEY_WEB="/var/www/apt/pubkey.gpg"

echo "==> generating GPG key for apt repo signing"

# Generate key non-interactively
gpg --batch --gen-key <<EOF
%no-protection
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${KEY_NAME}
Name-Email: ${KEY_EMAIL}
Expire-Date: ${KEY_KEY_EXPIRE}
%commit
EOF

echo "==> exporting key to ${KEYRING}"
gpg --export --output "${KEYRING}" "${KEY_NAME} <${KEY_EMAIL}>"
chmod 600 "${KEYRING}"

echo "==> copying public key to web root"
gpg --export --armor "${KEY_NAME} <${KEY_EMAIL}>" > "${PUBKEY_WEB}"
chmod 644 "${PUBKEY_WEB}"

echo "==> done. key fingerprint:"
gpg --list-keys --keyid-format long "${KEY_NAME}"
echo ""
echo "Private key stored at: ${KEYRING}"
echo "Public key available at: https://apt.realgoldfang.dev/pubkey.gpg"
echo ""
echo "BACKUP: Export the private key to a secure location:"
echo "  gpg --export-secret-keys '${KEY_NAME} <${KEY_EMAIL}>' > backup-key.gpg"
echo "  Store backup-key.gpg offline (e.g. encrypted USB, password manager)."
