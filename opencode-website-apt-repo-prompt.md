# Project: Personal Site + Personal APT Repository

## Context
Existing infra: Raspberry Pi tunneled via Tailscale to a public-facing AWS EC2 instance running nginx. Deployment currently managed via PM2. GitHub user: goldfang / cybernatedev-ship-it. Ubuntu 26.04 daily driver. Existing portfolio site (React + AI Twin chat widget) already deployed on this stack — treat this as either extending that site or standing up a second nginx vhost alongside it (your call, opencode, but keep them isolated so a repo rebuild can't break the portfolio site).

## Goal
Two deliverables, served from the same EC2/nginx box:

1. **Personal website** — public landing page / portfolio, static-first (no Node runtime dependency if avoidable), served directly by nginx.
2. **Personal APT repository** — a real `apt`-compatible repo (signed, with Release/Packages metadata) hosting `.deb` packages I build myself (e.g. mcp-sysd, Ad-Wolf builds, Devbuntu-related tooling), so I can `apt install` my own tools on any Ubuntu/Debian box after adding my repo + signing key.

## Part 1: Website
- Static site (plain HTML/CSS or a static site generator — Hugo or Astro preferred over a heavier framework). No build step requiring a long-running Node process on the server; build locally or in CI, deploy static output only.
- Pages: home/about, projects (Howler, Lupine, Devbuntu, Ad-Wolf, mcp-sysd, TI-Nspire tools — pull descriptions from README files if present in each repo), contact/links (GitHub).
- Dark theme by default, minimal, fast. Wolf motif is fine if it fits, not required.
- Deployed as static files under an nginx server block, e.g. `/var/www/site`.
- HTTPS via certbot/Let's Encrypt.

## Part 2: APT Repository
- Use **aptly** for repo management (preferred over raw reprepro unless opencode has a strong reason otherwise — aptly makes multi-distro/multi-arch and snapshot management simpler).
- Generate a dedicated GPG signing key for the repo (not my personal key). Store the private key only on the machine that publishes (Pi or EC2 — pick one, be explicit about which, and document the key's location and backup plan).
- Repo structure to support at minimum: `noble` (24.04) and `plucky`/current codename matching Ubuntu 26.04, amd64 + arm64 (Pi is arm64).
- Serve the repo root over nginx as static files (aptly publishes to a directory tree — nginx just needs to serve it) at a subpath or subdomain, e.g. `apt.<domain>` or `<domain>/apt`.
- Public signing key available for download at a stable URL (e.g. `apt.<domain>/pubkey.gpg`).
- Produce the exact `sources.list.d/*.list` snippet and `apt-key`/`signed-by` instructions end users (me) would need to add the repo on a fresh machine.
- CI: GitHub Actions workflow that, on tag/release in a source repo (start with mcp-sysd), builds the `.deb`, signs it into the aptly repo, and publishes updated repo metadata to the server (push over SSH/Tailscale, or pull-based via a script triggered on the server).
- Document the manual commands for adding/removing/updating a package in the repo without CI, since I'll want to do this ad hoc too.

## Infra integration notes
- nginx vhosts: one for the website, one for the APT repo (or one server block with two locations — opencode's call, explain the tradeoff briefly).
- Everything reachable only via the existing Tailscale-tunneled Pi → EC2 path where it makes sense; the APT repo itself needs to be public (that's the point), but any admin/publish endpoints (e.g. a webhook trigger) should be Tailscale-only or SSH-key-gated, not open to the internet.
- Keep this additive to the current PM2-managed deployment — don't restructure the existing portfolio site's deployment unless necessary, just note if it is.

## Deliverables
1. Working static site deployed and reachable.
2. Working aptly-based repo with at least one real package (mcp-sysd) published and installable via `apt install` after adding the repo.
3. A short README documenting: how to add a new package to the repo, how to rotate/rekey the signing key if needed, and the exact end-user setup instructions.
4. GitHub Actions workflow file(s) for automated builds where applicable.

## Non-goals
- No dynamic backend/database for the website unless a specific feature requires it — flag it if opencode thinks one's needed rather than assuming.
- Not migrating away from aptly/nginx to a SaaS APT hosting service.
