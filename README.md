# realgoldfang.github.io

Personal site + APT repository. Served from EC2 via nginx, tunneled through Tailscale from Raspberry Pi.

## Repository Structure

```
.
├── site/                    # Astro static site
│   ├── src/
│   │   ├── layouts/
│   │   ├── pages/
│   │   └── styles/
│   ├── public/
│   ├── astro.config.mjs
│   └── package.json
├── apt-repo/                # APT repository management
│   ├── conf/
│   │   └── aptly.conf       # aptly configuration
│   └── scripts/
│       ├── generate-repo-key.sh   # generate GPG signing key
│       ├── add-package.sh         # add a .deb to the repo
│       ├── remove-package.sh      # remove a package
│       ├── publish-repo.sh        # sign + publish all repos
│       └── rotate-key.sh          # rotate the signing key
├── nginx/
│   ├── realgoldfang-site.conf    # nginx vhost for website
│   ├── realgoldfang-apt.conf     # nginx vhost for apt repo
│   └── setup-nginx.sh           # enable sites on server
├── .github/workflows/
│   ├── deploy-site.yml              # deploy site on push
│   └── build-and-publish-deb.yml    # build + publish debs on tag
└── README.md
```

## End-User Setup

### Adding the APT Repository

On any Ubuntu/Debian machine:

```bash
# Add the signing key
curl -fsSL https://apt.realgoldfang.dev/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/goldfang.gpg

# Add the repository
echo "deb [signed-by=/etc/apt/keyrings/goldfang.gpg] https://apt.realgoldfang.dev stable main" | sudo tee /etc/apt/sources.list.d/goldfang.list

# Update and install
sudo apt update
sudo apt install mcp-sysd
```

### Supported Distributions

| Codename | Release | Architectures |
|----------|---------|---------------|
| noble | Ubuntu 24.04 | amd64, arm64 |
| plucky | Ubuntu 26.04 | amd64, arm64 |

## Adding a New Package

1. Build the `.deb` (or let CI do it on tag push)
2. Copy it to the server:
   ```bash
   scp build/mcp-sysd_1.0.0_amd64.deb server:/tmp/
   ```
3. Add to the repo:
   ```bash
   # SSH into the server
   cd /opt/goldfang-apt-repo
   ./scripts/add-package.sh noble /tmp/mcp-sysd_1.0.0_amd64.deb
   ```
4. Publish:
   ```bash
   ./scripts/publish-repo.sh
   ```

## Removing a Package

```bash
cd /opt/goldfang-apt-repo
./scripts/remove-package.sh noble mcp-sysd 1.0.0
```

## Rotating the Signing Key

If the key is compromised or annually:

```bash
cd /opt/goldfang-apt-repo
./scripts/rotate-key.sh
```

This will:
1. Generate a new GPG key
2. Re-sign all published repos
3. Update the public key at `https://apt.realgoldfang.dev/pubkey.gpg`

**Clients must re-download the key after rotation:**
```bash
curl -fsSL https://apt.realgoldfang.dev/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/goldfang.gpg
```

### Key Backup

Export the private key for offline backup:
```bash
gpg --export-secret-keys 'goldfang-apt-repo <apt@realgoldfang.dev>' > backup-key.gpg
```
Store this on an encrypted USB or in a password manager.

## Server Setup

### Prerequisites
- Ubuntu 24.04+ on EC2
- nginx installed
- aptly installed (`sudo apt install aptly`)
- Tailscale configured

### Initial Setup

```bash
# 1. Install aptly
sudo apt install aptly

# 2. Generate signing key
sudo ./apt-repo/scripts/generate-repo-key.sh

# 3. Copy aptly config
sudo cp apt-repo/conf/aptly.conf /etc/aptly.conf

# 4. Enable nginx sites
cd nginx && sudo ./setup-nginx.sh

# 5. Set up Let's Encrypt
sudo certbot --nginx -d realgoldfang.github.io
sudo certbot --nginx -d apt.realgoldfang.dev
```

### GitHub Actions Secrets

| Secret | Description |
|--------|-------------|
| `DEPLOY_SSH_KEY` | SSH private key for deploying site |
| `DEPLOY_HOST` | EC2 hostname (via Tailscale) |
| `DEPLOY_USER` | SSH user on EC2 |
| `APTLY_SSH_KEY` | SSH key for aptly server |
| `APTLY_HOST` | Aptly server hostname |
| `APTLY_USER` | SSH user on aptly server |

## Deployment

- **Site**: Push to `main` triggers `deploy-site.yml`, which builds Astro and deploys static files to `/var/www/site`
- **APT packages**: Push a tag (`v*`) triggers `build-and-publish-deb.yml`, which builds the `.deb` for amd64 + arm64 and publishes to the aptly repo

## Architecture Notes

- Two separate nginx server blocks: website and apt repo. A broken aptly publish can't take down the portfolio site.
- The APT repo is public (that's the point). Admin endpoints (aptly, webhook triggers) are Tailscale-only.
- PM2-managed deployment for the existing portfolio site is unaffected.
