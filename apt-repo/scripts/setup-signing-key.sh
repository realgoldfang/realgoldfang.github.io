#!/usr/bin/env bash
# setup-signing-key.sh
# Imports the GPG signing key from an environment variable into the keyring.
# Used in CI — the private key is stored as a GitHub Actions encrypted secret.
#
# Expects: APTLY_GPG_KEY (base64-encoded secret key)

set -euo pipefail

KEY_NAME="goldfang-apt-repo"
KEY_EMAIL="apt@realgoldfang.dev"

if [ -z "${APTLY_GPG_KEY:-}" ]; then
  echo "error: APTLY_GPG_KEY not set"
  exit 1
fi

echo "==> importing GPG key"
echo "${APTLY_GPG_KEY}" | base64 -d | gpg --batch --import

echo "==> configuring gpg to use this key for signing"
cat > /tmp/gpg.conf << EOF
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-cipher SHA512 SHA384 SHA256 AES256 AES192 AES
default-preference-digest SHA512 SHA384 SHA256
default-preference-compress ZLIB BZIP2 ZIP Uncompressed
keyid-format 0xlong
with-fingerprint
EOF

echo "==> done. key available for aptly signing"
gpg --list-keys --keyid-format long "${KEY_NAME}"
