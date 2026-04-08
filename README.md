# .github

Organisation-wide GitHub configuration for Claude Code automation (ONEBCG v2026).

## What this repo does

This repo automatically provisions every new repository in the org with AI-assisted workflows, enterprise quality gates, and governance policies.

### Productivity workflows (auto-provisioned to every repo)

- **PR summaries** — Claude posts a 4-section structured summary on every pull request (What / Files changed / Issues found / Reviewer checklist)
- **@claude reviews** — developers mention `@claude` in any PR comment to ask questions about the diff; Claude answers with project context from `CLAUDE.md`
- **Security scanning** — every push to `main`/`master` is scanned for OWASP Top 10 vulnerabilities; issues are auto-raised with a `security` label
- **Release notes** — pushing a `v*` tag collects up to 50 commits, generates plain-English release notes (Features / Improvements / Fixes), and creates a GitHub Release

### Enterprise quality workflows (auto-provisioned to every repo)

- **CI build & test** — builds and runs the test suite on every push and PR, with multi-runtime matrix support
- **Lint** — code style, formatting, and branch naming convention checks on every push and PR
- **Dependency review** — blocks PRs that introduce high/critical CVE dependencies or forbidden licences (GPL/AGPL)
- **Code coverage** — enforces a minimum 80% line coverage threshold; posts delta comment on PR
- **Stale issues & PRs** — auto-marks inactive items after 30 days and closes after a further 7 days
- **Release drafter** — auto-drafts next release notes from PR labels as PRs are merged into `main`

### Policies applied to every repo on provisioning

- **Branch protection** — `main` requires 2 approvers, code owner review, signed commits, up-to-date branch, and all required status checks; force-push and deletion are blocked
- **Repo settings** — squash-merge only, delete branch on merge, wiki/projects disabled, default branch set to `main`
- **Security features** — vulnerability alerts, secret scanning, push protection, and Dependabot auto-updates enabled automatically

### Org-wide governance workflows (run in this repo)

- **PR gate** — orchestrates lint + build + test + dependency-review as a single required status check
- **Deploy workflows** — parameterisable CD pipelines for `dev` (on `develop` push), `staging` (on `release/**`/`hotfix/**`), and `production` (on `v*` tag)
- **Audit repo settings** — nightly re-enforcement of policy settings across all repos; drift triggers a Google Chat alert and a GitHub issue
- **Enforce quality gate** — weekly cross-org report of failing security scans and PR gates; posts to Google Chat and raises an issue
- **Rotate stale secrets** — weekly check for org secrets whose names follow the `*_EXPIRES_YYYYMMDD` convention and are within 30 days of expiry

### Issue & PR templates (org-wide defaults)

Structured GitHub Forms for **Bugs**, **Epics**, **Tasks**, **Sub-tasks**, and **User Stories** — with required/optional fields for priority, severity, estimates, and traceability links.

**PR template** — structured checklist covering: linked issue, change type, description, testing evidence, security checklist, deployment notes, screenshots, and reviewer guidance.

---

## Folder structure

```
.github/
├── workflows/
│   ├── ci/
│   │   └── pr-gate.yml                  # Orchestrates lint + build + test + dep-review
│   ├── cd/
│   │   ├── deploy-dev.yml               # Auto-deploy develop → dev environment
│   │   ├── deploy-staging.yml           # Deploy release/** → staging (with reviewer gate)
│   │   └── deploy-prod.yml              # Deploy v* tag → production (2-approver + rollback)
│   ├── governance/
│   │   ├── audit-repo-settings.yml      # Nightly drift detection & remediation
│   │   └── rotate-stale-secrets.yml     # Weekly expiring-secret reminder
│   ├── productivity/
│   │   ├── claude-review.yml            # @claude mention handler (claude-sonnet-4-6)
│   │   ├── pr-summary.yml               # Auto PR summary on open/sync
│   │   └── release-notes.yml            # Tag-based release notes generator
│   ├── quality-gates/
│   │   └── enforce-quality-gate.yml     # Weekly org-wide quality gate report
│   └── security/
│       └── security-scan.yml            # Push-to-main OWASP security scan
├── workflow-templates/
│   ├── dev/
│   │   ├── ci-build-test.yml            # Build + test (multi-runtime matrix)
│   │   ├── ci-lint.yml                  # Linting + branch naming convention
│   │   └── dependency-review.yml        # Block high/critical CVE dependencies
│   ├── quality/
│   │   ├── code-coverage.yml            # Coverage check + PR delta comment (≥80%)
│   │   ├── sonarcloud.yml               # SonarCloud static analysis + quality gate
│   │   └── licence-check.yml            # Block GPL/AGPL licences
│   └── business/
│       ├── stale-issues.yml             # Mark stale after 30d, close after 7d
│       └── release-drafter.yml          # Auto-draft release notes from PR labels
├── repo-templates/
│   ├── CLAUDE-dotnet.md                 # .NET 8, C#, EF Core, React 18, AWS
│   ├── CLAUDE-python.md                 # Django / FastAPI / Flask / Celery / SQLAlchemy
│   ├── CLAUDE-default.md                # Fallback for unrecognised stacks
│   └── .claudeignore                    # Excludes migrations, build output, lock files
├── scripts/
│   ├── bootstrap/
│   │   ├── resolve-template.sh          # Matches repo language/description → CLAUDE-*.md
│   │   └── apply-template.sh            # Clones repo, copies files, commits, pushes
│   └── governance/
│       ├── apply-branch-rules.sh        # Applies branch-protection.json + repo-rules.json
│       └── enforce-settings.sh          # Enforces merge strategy, security features
├── policies/
│   ├── branch-protection.json           # Branch protection rules for main + develop
│   ├── environments.json                # dev / staging / production environment definitions
│   └── repo-rules.json                  # Org ruleset + repo settings policy
├── ISSUE_TEMPLATE/
│   ├── bug.yml
│   ├── epic.yml
│   ├── task.yml
│   ├── sub_task.yml
│   └── user_story.yml
└── PULL_REQUEST_TEMPLATE/
    └── pull_request_template.md         # Structured PR checklist
```

---

## What gets copied to every new repo

`apply-template.sh` is run automatically within 15 minutes of a new repo being created (or immediately via webhook). It provisions the following:

| File | Behaviour |
|---|---|
| `.github/workflows/pr-summary.yml` | Always overwritten |
| `.github/workflows/claude-review.yml` | Always overwritten |
| `.github/workflows/security-scan.yml` | Always overwritten |
| `.github/workflows/release-notes.yml` | Always overwritten |
| `.github/workflows/ci-build-test.yml` | Always overwritten |
| `.github/workflows/ci-lint.yml` | Always overwritten |
| `.github/workflows/dependency-review.yml` | Always overwritten |
| `.github/workflows/code-coverage.yml` | Always overwritten |
| `.github/workflows/stale-issues.yml` | Always overwritten |
| `.github/workflows/release-drafter.yml` | Always overwritten |
| `CLAUDE.md` | Only copied if **not** already present |
| `.claudeignore` | Only copied if **not** already present |
| `.github/PULL_REQUEST_TEMPLATE/pull_request_template.md` | Only copied if **not** already present |

After commit/push, `apply-template.sh` calls:
1. `apply-branch-rules.sh` — applies `policies/branch-protection.json` and the org ruleset
2. `enforce-settings.sh` — sets merge strategy, disables wiki/projects, enables all security features

---

## How template selection works

`resolve-template.sh` lowercases and combines the repo's **description** and **primary language**, then keyword-matches in priority order:

| Keywords matched | Template selected |
|---|---|
| `dotnet`, `.net`, `csharp`, `c#` | `CLAUDE-dotnet.md` |
| `python`, `django`, `fastapi`, `flask`, `celery` | `CLAUDE-python.md` |
| `flutter`, `dart` | `CLAUDE-flutter.md` *(future)* |
| `java`, `kotlin`, `spring` | `CLAUDE-java.md` *(future)* |
| `go`, `golang` | `CLAUDE-go.md` *(future)* |
| `node`, `typescript`, `express` | `CLAUDE-node.md` *(future)* |
| *(no match)* | `CLAUDE-default.md` |

---

## Required secrets

| Secret | Scope | Purpose |
|---|---|---|
| `ANTHROPIC_API_KEY` | Org-level | Claude API access (`claude-sonnet-4-6`) for all CI workflows |
| `ORG_PROVISIONING_PAT` | Org-level | Clone/push to target repos; read org repo list for governance workflows |
| `APP_ID` | This repo | GitHub App ID for webhook receiver |
| `APP_PRIVATE_KEY` | This repo | GitHub App private key for webhook receiver |
| `SONAR_TOKEN` | Org-level *(optional)* | SonarCloud analysis for `sonarcloud.yml` |
| `GOOGLE_CHAT_WEBHOOK_URL` | Org-level *(optional)* | Post governance alerts to Google Chat |

---

## Branch conventions (enforced by policy)

| Pattern | Purpose |
|---|---|
| `main` | Production-ready; 2 approvers required |
| `develop` | Integration branch; 1 approver required |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `hotfix/*` | Urgent production fixes |
| `release/*` | Release candidates |
| `chore/*` | Maintenance, deps, tooling |
| `docs/*` | Documentation only |

Branch names not matching these patterns are rejected by `ci-lint.yml`.

---

## Environment gates

| Environment | Trigger | Required approvers | Wait |
|---|---|---|---|
| `dev` | Push to `develop` | None | 0 min |
| `staging` | Push to `release/**` or `hotfix/**` | QA team | 0 min |
| `production` | Push of `v*` tag | Tech leads + DevOps | 5 min |

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

## Setup guide

Full setup instructions (accounts, secrets, GitHub App, branch protection, eng-ops reporting) are covered in the implementation playbook.
