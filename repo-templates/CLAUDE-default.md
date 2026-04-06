# CLAUDE.md

## Stack

> Update this section with the actual stack for this project.

- Language: TBD
- Framework: TBD
- Database: TBD
- Infrastructure: TBD
- CI/CD: GitHub Actions

## Architecture

> Describe the high-level structure of this repo (e.g. monolith, microservice, layered architecture, key modules).

## Coding Standards

- Write tests for all new public methods and API endpoints
- No hardcoded secrets, connection strings, or API keys — use environment variables or secret managers
- Handle errors explicitly; do not swallow exceptions silently
- Remove all `console.log`, `print`, and debug statements before merging
- Follow the existing naming conventions in the codebase

## Issues to Flag in Reviews

- Unhandled exceptions or empty catch blocks
- Logic that duplicates existing utilities in the codebase
- Missing input validation at API boundaries
- Sensitive data written to logs
- Hardcoded environment-specific values (URLs, ports, credentials)

## Do Not

- Modify CI/CD workflows without review from the engineering lead
- Add new dependencies without listing them in the PR description for review
- Push directly to `main` or `master` — all changes must go through a PR
- Merge a PR with failing checks
