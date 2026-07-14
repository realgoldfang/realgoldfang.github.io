# realgoldfang.github.io

Personal site + APT repository. Hosted on GitHub Pages.

## Repository Structure

```
.
├── site/                          # Astro static site source
│   ├── src/
│   │   ├── layouts/Base.astro
│   │   └── pages/
│   │       ├── index.astro        # home (fetches Devbuntu + Ad-Wolf releases)
│   │       ├── about.astro
│   │       ├── projects.astro     # apt packages + download links
│   │       ├── apt.astro          # repo setup instructions
│   │       └── contact.astro
│   ├── public/
│   │   └── apt/pubkey.gpg         # public signing key (committed)
│   ├── astro.config.mjs
│   └── package.json
├── apt-repo/                      # APT repository management
│   ├── conf/aptly.conf
│   ├── scripts/
│   │   ├── setup-signing-key.sh   # import GPG key from CI secret
│   │   ├── init-repo.sh           # initialize aptly repo for a codename
│   │   ├── add-package.sh         # add a .deb to the repo
│   │   ├── remove-package.sh      # remove a package
│   │   ├── publish.sh             # sign + publish all repos
│   │   ├── export-pubkey.sh       # export public key
│   │   └── rotate-key.sh          # rotate the signing key
│   └── public/                    # published apt repo tree (committed)
├── .github/workflows/
│   ├── deploy-site.yml            # build site + deploy to Pages
│   └── build-deb.yml              # build debs + aptly publish + commit
└── README.md
```

## Architecture

- **Site**: Astro static site deployed to `realgoldfang.github.io` via GitHub Pages
- **APT repo**: static tree at `realgoldfang.github.io/apt/`, built by aptly in CI
- **No servers**: everything runs on GitHub Actions + Pages. No EC2, no nginx, no Tailscale.
- **Devbuntu + Ad-Wolf**: download links fetched from GitHub Releases API at build time (not APT packages — they produce ISOs and APKs)

## End-User Setup

### Adding the APT Repository

```bash
# 1. add the signing key
curl -fsSL https://realgoldfang.github.io/apt/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/goldfang.gpg

# 2. add the repository
echo "deb [signed-by=/etc/apt/keyrings/goldfang.gpg] https://realgoldfang.github.io/apt stable main" | sudo tee /etc/apt/sources.list.d/goldfang.list

# 3. install
sudo apt update && sudo apt install mcp-sysd
```

### Supported Distributions

| Codename | Release | Architectures |
|----------|---------|---------------|
| noble | Ubuntu 24.04 | amd64, arm64 |
| plucky | Ubuntu 26.04 | amd64, arm64 |

## Adding a New Package

### Via CI (recommended)

Each source repo triggers the `build-deb.yml` workflow via `repository_dispatch` on release:

```json
{
  "event_type": "release-published",
  "client_payload": {
    "package": "mcp-sysd",
    "tag": "v1.0.0",
    "repo": "realgoldfang/mcp-sysd"
  }
}
```

Or use `workflow_dispatch` from the Actions tab.

### Manual Local Commands

```bash
# 1. install aptly
sudo apt install aptly

# 2. import the signing key
gpg --import private-key.gpg

# 3. initialize repos (first time only)
./apt-repo/scripts/init-repo.sh noble
./apt-repo/scripts/init-repo.sh plucky

# 4. add a package
./apt-repo/scripts/add-package.sh noble ./mcp-sysd_1.0.0_amd64.deb

# 5. publish
./apt-repo/scripts/publish.sh apt-repo/public

# 6. commit and push
git add apt-repo/public/
git commit -m "apt: update repo with mcp-sysd v1.0.0"
git push
```

## Removing a Package

```bash
./apt-repo/scripts/remove-package.sh noble mcp-sysd 1.0.0
# then publish + commit
```

## Rotating the Signing Key

```bash
./apt-repo/scripts/rotate-key.sh
```

This generates a new key and prints instructions. After rotation:
1. Update the `APTLY_GPG_KEY` GitHub Actions secret with the new private key (base64-encoded)
2. Update `site/public/apt/pubkey.gpg` with the new public key
3. Commit and push — clients must re-download the key:
   ```bash
   curl -fsSL https://realgoldfang.github.io/apt/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/goldfang.gpg
   ```

## GitHub Actions Secrets

| Secret | Description |
|--------|-------------|
| `APTLY_GPG_KEY` | Base64-encoded GPG private key for apt repo signing |

## Workflows

| Workflow | Trigger | What it does |
|----------|---------|--------------|
| `deploy-site.yml` | push to main | builds Astro site, copies apt repo tree, deploys to Pages |
| `build-deb.yml` | repository_dispatch / workflow_dispatch | builds .deb, runs aptly, commits updated repo tree |
