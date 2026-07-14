#!/usr/bin/env bash
# Sets the APT_PAT GitHub Actions secret on each source repo and updates
# their publish-to-apt.yml to reference secrets.APT_PAT.
set -euo pipefail

if [[ -z "${APT_PAT:-}" ]]; then
    echo "Error: \$APT_PAT is not set in this shell. Run: source ~/.bashrc" >&2
    exit 1
fi

REPOS=(
    Backup-Util
    Howler
    Luna-rs
    RuSStly
    TI-nspire-transfer
    custom-home-display
    devbuntu-web
)

GH_OWNER="realgoldfang"
PROJECTS_DIR="$HOME/projects"
WORKFLOW_REL_PATH=".github/workflows/publish-to-apt.yml"

for name in "${REPOS[@]}"; do
    repo_path="$PROJECTS_DIR/$name"
    echo "=== $name ==="

    if [[ ! -d "$repo_path/.git" ]]; then
        echo "  skip: not a git repo"
        continue
    fi

    # 1. Set the secret on GitHub
    gh secret set APT_PAT --body "$APT_PAT" --repo "$GH_OWNER/$name"

    # 2. Swap the secret reference in the workflow yaml, if present
    yaml_path="$repo_path/$WORKFLOW_REL_PATH"
    if [[ -f "$yaml_path" ]] && grep -q "secrets.APT_REPO_TOKEN" "$yaml_path"; then
        sed -i 's/secrets\.APT_REPO_TOKEN/secrets.APT_PAT/' "$yaml_path"
        (
            cd "$repo_path"
            git add "$WORKFLOW_REL_PATH"
            if ! git diff --cached --quiet; then
                git commit -m "ci: use APT_PAT secret name"
                git push
            fi
        )
    fi
    echo
done

echo "Done."
