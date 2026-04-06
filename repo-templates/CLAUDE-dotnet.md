# CLAUDE.md

## Stack

- **Backend**: .NET 8, C#, ASP.NET Core, Entity Framework Core
- **Database**: SQL Server (EF Core migrations)
- **Frontend**: React 18, TypeScript, Vite
- **Infrastructure**: AWS (ECS, RDS, S3, Lambda, CloudWatch)
- **CI/CD**: GitHub Actions

## Architecture

Layered architecture:
- `API/` — ASP.NET Core controllers, middleware, DI registration
- `Application/` — CQRS commands/queries (MediatR), validators (FluentValidation)
- `Domain/` — entities, value objects, domain events
- `Infrastructure/` — EF Core DbContext, repositories, AWS SDK clients, external service adapters
- `Frontend/` — React SPA (communicates with API via `/api/*` routes)

## Coding Standards

- Use `async`/`await` throughout — never `.Result` or `.Wait()`
- Add `AsNoTracking()` on all read-only EF Core queries
- Use parameterised queries or EF Core — never string-concatenated SQL
- Write xUnit tests for all Application layer handlers; use `Moq` for dependencies
- Use `IOptions<T>` for configuration — no `ConfigurationManager.AppSettings` direct access
- Dispose `IDisposable` resources — prefer `using` declarations
- Return `IActionResult` / `ActionResult<T>` from controllers; never throw HTTP exceptions manually
- Use `CancellationToken` on all async controller actions and service calls

## Issues to Flag in Reviews

- **EF Core N+1**: Loading a collection inside a loop without `.Include()` or a batch query
- **Missing `AsNoTracking()`**: Any read-only query that fetches entities without it
- **String-concatenated SQL**: Any `$"SELECT ... WHERE id = {id}"` pattern — must use parameters
- **Missing unit tests**: New Application handlers or domain logic with no test coverage
- **Hardcoded secrets**: Connection strings, API keys, or passwords in source code
- **AWS SDK without retry config**: `AmazonS3Client` or similar instantiated without `RetryMode`
- **Synchronous I/O**: File reads, HTTP calls, or DB queries without `await`
- **Missing input validation**: Controller actions accepting complex types without FluentValidation

## Do Not

- Modify EF Core migrations manually after they have been applied to staging or production
- Add NuGet packages without listing them in the PR description for architect review
- Use `dynamic` or reflection unless absolutely necessary
- Modify `.github/workflows/` without architect review
- Push directly to `main` — all changes require a reviewed PR
