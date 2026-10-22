#!/usr/bin/env bash
# Set CLAUDE_CODE_OAUTH_TOKEN as a repo secret on Splitzzyy repos.
# Free plan: org secrets don't reach private repos, so set it per repo.
#   bash scripts/set-secret.sh              # all org repos
#   bash scripts/set-secret.sh repo1 repo2  # only these
set -euo pipefail

ORG=Splitzzyy

read -rsp "Paste CLAUDE_CODE_OAUTH_TOKEN (from 'claude setup-token'): " TOKEN
echo
[ -n "$TOKEN" ] || { echo "Empty token, aborting." >&2; exit 1; }

if [ $# -gt 0 ]; then
  repos=("$@")
else
  mapfile -t repos < <(gh repo list "$ORG" --limit 200 --no-archived --json name --jq '.[].name')
fi

for r in "${repos[@]}"; do
  gh secret set CLAUDE_CODE_OAUTH_TOKEN -R "$ORG/$r" --body "$TOKEN" && echo "✓ $r"
done
