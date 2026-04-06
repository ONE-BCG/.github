# .github

Organisation-wide GitHub configuration for Claude Code automation.

## What this repo does

This repo automatically provisions every new repository in the org with:

- **PR summaries** — Claude posts a structured summary comment on every pull request
- **@claude reviews** — developers can mention `@claude` in any PR comment to ask questions about the diff
- **Security scanning** — every push to `main`/`master` is scanned for common vulnerabilities
- **Release notes** — pushing a `v*` tag generates plain-English release notes and creates a GitHub Release

Provisioning runs automatically within 15 minutes of a new repo being created, or immediately via webhook.

## Folder structure

```
.github/
├── .github/workflows/
│   └── provision-new-repo.yml   # Provisions new repos (webhook + 15-min schedule)
├── workflow-templates/
│   ├── pr-summary.yml           # Auto PR summary comment
│   ├── claude-review.yml        # @claude mention handler
│   ├── security-scan.yml        # Push-to-main security scan
│   └── release-notes.yml        # Tag-based release notes generator
├── repo-templates/
│   ├── CLAUDE-dotnet.md         # .NET 8, C#, EF Core, React, AWS
│   ├── CLAUDE-python.md         # Django / FastAPI / Flask / Celery
│   ├── CLAUDE-default.md        # Fallback for unrecognised stacks
│   └── .claudeignore            # Excludes generated files, build output, lock files
└── scripts/
    ├── resolve-template.sh      # Matches repo language/description → template
    └── apply-template.sh        # Clones repo, copies files, commits, pushes
```

## How template selection works

`resolve-template.sh` checks the repo's **description first**, then its **language**, using keyword matching:

| Keywords matched | Template selected |
|---|---|
| `dotnet`, `.net`, `csharp`, `c#` | `CLAUDE-dotnet.md` |
| `python`, `django`, `fastapi`, `flask`, `celery` | `CLAUDE-python.md` |
| *(no match)* | `CLAUDE-default.md` |

## Required secrets

| Secret | Scope | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | Org-level | Claude API access for all CI workflows |
| `ORG_PROVISIONING_PAT` | Org-level | Clone and push to target repos during provisioning |
| `APP_ID` | This repo | GitHub App ID for webhook receiver |
| `APP_PRIVATE_KEY` | This repo | GitHub App private key for webhook receiver |
| `GOOGLE_CHAT_WEBHOOK_URL` | Org-level *(optional)* | Post reports to Google Chat |

## Manual provisioning

To provision a specific repo immediately without waiting for the schedule:

```
Actions → Provision New Repo → Run workflow
```

Or trigger via the GitHub API:

```bash
gh api repos/YOUR-ORG/.github/dispatches \
  --method POST \
  --field event_type=provision \
  --field client_payload='{"repo":"YOUR-ORG/repo-name","language":"C#","description":"client portal"}'
```

## Setup guide

Full setup instructions (accounts, secrets, GitHub App, branch protection, eng-ops reporting) are covered in the implementation playbook.
