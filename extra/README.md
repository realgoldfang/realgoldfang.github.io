# APT Repo Trigger Workflow

Drop `publish-to-apt.yml` into `.github/workflows/` in each source repo:

- `realgoldfang/mcp-sysd`
- `realgoldfang/howler`
- `realgoldfang/lupine`
- `realgoldfang/nspire-tools` (or `nspire-cli`, `nspire-gui` — it normalizes)

## Setup

1. Create a Personal Access Token (classic) with `repo` scope
2. Add it as `APT_REPO_TOKEN` in each source repo's Settings → Secrets
3. Copy `publish-to-apt.yml` to `.github/workflows/` in each repo
4. Push, then create a release — it triggers `build-deb.yml` in the apt repo

## What happens

```
source repo release published
  → sends repository_dispatch to realgoldfang.github.io
    → build-deb.yml runs
      → builds .deb, signs with aptly, commits to apt-repo/public/
        → deploy-site.yml runs
          → site + apt repo deployed to Pages
```
