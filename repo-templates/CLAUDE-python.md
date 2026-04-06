# CLAUDE.md

## Stack

- **Framework**: Django / FastAPI / Flask (update as appropriate)
- **ORM**: SQLAlchemy / Django ORM
- **Task Queue**: Celery + Redis
- **Database**: PostgreSQL
- **Infrastructure**: AWS (ECS, RDS, S3) or as configured
- **CI/CD**: GitHub Actions

## Architecture

- `app/` or `src/` — application code
- `models/` — ORM models / database schema
- `services/` — business logic, separated from views/routes
- `tasks/` — Celery async tasks
- `tests/` — pytest test suite
- `migrations/` — Alembic or Django migrations (auto-generated, do not edit manually)

## Coding Standards

- Use type hints on all function signatures (`def get_user(user_id: int) -> User:`)
- Use `async`/`await` in FastAPI route handlers — no blocking I/O on the event loop
- Always use parameterised queries — never f-string or %-format SQL
- Handle exceptions explicitly; do not use bare `except:` clauses
- Use environment variables for all secrets (via `python-dotenv` or `os.environ`)
- Write pytest tests for all service-layer functions and API endpoints
- Use `pytest-asyncio` for async route tests
- Remove all `print()` debug statements before merging

## Issues to Flag in Reviews

- **Raw SQL with f-strings**: Any `f"SELECT ... WHERE id = {id}"` pattern
- **Bare `except:`**: Catches all exceptions including `KeyboardInterrupt` and `SystemExit`
- **Blocking I/O in async routes**: `requests.get()`, `time.sleep()`, or synchronous DB calls inside `async def`
- **Missing test coverage**: New service functions or endpoints with no pytest tests
- **Hardcoded credentials**: Any string that looks like a secret, token, or password in source
- **N+1 queries**: Iterating over ORM objects and calling `.related_model` inside the loop without `select_related` / `joinedload`
- **Celery tasks without retry logic**: Tasks that call external APIs without `autoretry_for` or `bind=True` retry handling

## Do Not

- Edit migration files manually after they have been applied to staging or production
- Add pip packages without updating `requirements.txt` or `pyproject.toml` and noting them in the PR
- Store secrets in Django `settings.py` or commit `.env` files
- Modify `.github/workflows/` without architect review
- Push directly to `main` — all changes require a reviewed PR
