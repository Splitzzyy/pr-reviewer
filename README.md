# pr-reviewer

Central Claude PR review for all `Splitzzyy` repos. A repo opts in with `review: true` and picks a profile (`backend`, `ui`, `android`), and Claude posts inline comments plus a summary on every PR.

## Enable in a repo

Add `.github/workflows/pr-review.yml`:

```yaml
name: PR Review
on:
  pull_request:
    types: [opened, synchronize, ready_for_review, reopened]
jobs:
  review:
    permissions:
      contents: read
      pull-requests: write
      issues: write
    uses: Splitzzyy/pr-reviewer/.github/workflows/review.yml@main
    with:
      review: true          # false = turned off
      type: backend         # backend | ui | android
      # extra_prompt: |     # optional repo-specific rules
      #   We use EF Core; flag any raw SQL.
    secrets: inherit
```

The repo also needs the secret (see below).

## Secret setup

On the Free plan, org secrets aren't available to private repos, so the token is set per repo:

```bash
claude setup-token                      # copy the token
bash scripts/set-secret.sh              # all org repos
bash scripts/set-secret.sh splitzy-ui   # or specific repos
```

Rerun the script when the token rotates or a new repo is added.

## Edit or add prompts

- `prompts/_common.md`: rules for every review (severity tags, summary format).
- `prompts/<type>.md`: stack-specific focus. Add a new file such as `prompts/devops.md` and repos can use `type: devops` right away.

Changes on `main` apply to every repo on its next PR.

## Notes

- Draft PRs and PRs from forks are skipped (forks don't get secrets).
- A new push cancels the in-progress review for that PR.
