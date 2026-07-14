#!/usr/bin/env bash
# rotate-key.sh
# Rotates the GPG signing key for the apt repository.
#
# Run this on the publishing server. This will:
# 1. Generate a new key
# 2. Re-sign all published repos with the new key
# 3. Update the web-accessible public key
# 4. Remind you to update client machines

set -euo pipefail

OLD_KEY="goldfang-apt-repo"
NEW_KEY_NAME="goldfang-apt-repo-$(date +%Y%m%d)"
KEY_EMAIL="apt@realgoldfang.dev"
KEYRING="/etc/apt/repo-signing-key.gpg"
PUBKEY_WEB="/var/www/apt/pubkey.gpg"

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

echo "==> exporting new key"
gpg --export --output "${KEYRING}" "${NEW_KEY_NAME} <${KEY_EMAIL}>"
chmod 600 "${KEYRING}"

# Update web public key (show both old and new during transition)
gpg --export --armor "${NEW_KEY_NAME} <${KEY_EMAIL}>" > "${PUBKEY_WEB}"
chmod 644 "${PUBKEY_WEB}"

echo "==> re-publishing all repos with new key"
for CODENAME in noble plucky; do
  aptly publish update \
    -batch \
    -gpg-key="${NEW_KEY_NAME} <${KEY_EMAIL}>" \
    "${CODENAME}" filesystem:nginx-repo 2>/dev/null || true
done

echo ""
echo "==> key rotation complete"
echo ""
echo "NEW PUBLIC KEY fingerprint:"
gpg --list-keys --keyid-format long "${NEW_KEY_NAME}"
echo ""
echo "CLIENTS MUST RE-ADD THE KEY:"
echo "  curl -fsSL https://apt.realgoldfang.dev/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/goldfang.gpg"
echo ""
echo "BACKUP the new private key:"
echo "  gpg --export-secret-keys '${NEW_KEY_NAME} <${KEY_EMAIL}>' > backup-key-$(date +%Y%m%d).gpg"
