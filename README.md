# .github

Organisation-wide GitHub configuration for Claude Code automation (ONEBCG v2026).

## What this repo does

This repo automatically provisions every new repository in the org with AI-assisted workflows and enforces governance standards across all repos.

### Productivity workflows (auto-provisioned to every repo)

- **PR summaries** — Claude posts a 4-section structured summary on every pull request (What / Files changed / Issues found / Reviewer checklist)
- **@claude reviews** — developers mention `@claude` in any PR comment to ask questions about the diff; Claude answers with project context from `CLAUDE.md`
- **Security scanning** — every push to `main`/`master` is scanned for OWASP Top 10 vulnerabilities; issues are auto-raised with a `security` label
- **Release notes** — pushing a `v*` tag collects up to 50 commits, generates plain-English release notes (Features / Improvements / Fixes), and creates a GitHub Release

### Issue & PR templates (org-wide defaults)

Structured GitHub Forms for **Bugs**, **Epics**, **Tasks**, **Sub-tasks**, and **User Stories** — with required/optional fields for priority, severity, estimates, and traceability links (intent, requirements, test cases, Claude session links).

### Policies *(in progress)*

Placeholder configuration files for **branch protection**, **environments**, and **repo rules** — to be enforced via governance scripts.

---

## Folder structure

```
.github/
├── workflows/
│   ├── productivity/
│   │   ├── claude-review.yml        # @claude mention handler (claude-sonnet-4-6)
│   │   ├── pr-summary.yml           # Auto PR summary on open/sync
│   │   └── release-notes.yml        # Tag-based release notes generator
│   └── security/
│       └── security-scan.yml        # Push-to-main OWASP security scan
├── workflow-templates/
│   ├── business/                    # (placeholder — future business workflows)
│   ├── dev/                         # (placeholder — future dev workflows)
│   └── quality/                     # (placeholder — future quality workflows)
├── repo-templates/
│   ├── CLAUDE-dotnet.md             # .NET 8, C#, EF Core, React 18, AWS
│   ├── CLAUDE-python.md             # Django / FastAPI / Flask / Celery / SQLAlchemy
│   ├── CLAUDE-default.md            # Fallback for unrecognised stacks
│   └── .claudeignore                # Excludes migrations, build output, lock files
├── scripts/
│   ├── bootstrap/
│   │   ├── resolve-template.sh      # Matches repo language/description → CLAUDE-*.md
│   │   └── apply-template.sh        # Clones repo, copies files, commits, pushes
│   └── governance/
│       ├── apply-branch-rules.sh    # (placeholder)
│       └── enforce-settings.sh      # (placeholder)
├── policies/
│   ├── branch-protection.json       # (placeholder)
│   ├── environments.json            # (placeholder)
│   └── repo-rules.json              # (placeholder)
├── ISSUE_TEMPLATE/
│   ├── bug.yml
│   ├── epic.yml
│   ├── task.yml
│   ├── sub_task.yml
│   └── user_story.yml
└── PULL_REQUEST_TEMPLATE/           # (placeholder)
```

---

## How template selection works

`resolve-template.sh` lowercases and combines the repo's **description** and **primary language**, then keyword-matches in priority order:

| Keywords matched | Template selected |
|---|---|
| `dotnet`, `.net`, `csharp`, `c#` | `CLAUDE-dotnet.md` |
| `python`, `django`, `fastapi`, `flask`, `celery` | `CLAUDE-python.md` |

| *(no match)* | `CLAUDE-default.md` |

`apply-template.sh` then clones the target repo, **always overwrites** the 4 standard workflow files, and **preserves** any existing `CLAUDE.md` / `.claudeignore` the team has customised.

---

## Required secrets

| Secret | Scope | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | Org-level | Claude API access (`claude-sonnet-4-6`) for all CI workflows |
| `ORG_PROVISIONING_PAT` | Org-level | Clone and push to target repos during provisioning |
| `APP_ID` | This repo | GitHub App ID for webhook receiver |
| `APP_PRIVATE_KEY` | This repo | GitHub App private key for webhook receiver |

---

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

---

## Issue templates

| Template | Purpose | Key required fields |
|---|---|---|
| `bug.yml` | Bug reports | Description, Steps to Reproduce, Bug Type, Priority, Severity |
| `epic.yml` | Epics / Features | Priority |
| `task.yml` | Generic tasks | *(all optional)* — includes Claude Session Link, stakeholder sign-offs |
| `sub_task.yml` | Sub-tasks linked to parent | *(all optional)* — includes Claude Session Link |
| `user_story.yml` | User stories | Intent.md link, Requirements.md link, TestCases.md link |

---

## Setup guide

Full setup instructions (accounts, secrets, GitHub App, branch protection, eng-ops reporting) are covered in the implementation playbook.
