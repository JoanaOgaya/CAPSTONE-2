# FOMS ENGINEERING CONVENTIONS

## Stack (final, do not substitute)
- Frontend: React 19, TypeScript 5.6, Vite, React Router DOM 7, Recharts, Lucide React, Vanilla CSS with CSS variable tokens (Speedex Design System v2.0, NO Tailwind), Context API, fetch API (no Axios), jsPDF + AutoTable for PDF, SheetJS (xlsx) for Excel, Playwright, ESLint.
- Core backend: ASP.NET Core on .NET 10, C#, EF Core 10, MSSQL, JWT bearer, Swagger, Clean Architecture (Domain, Application, Infrastructure, Api). Modular core: Identity, Billing, FinanceOperations, Reporting are separate modules inside the core. Not microservices.
- AI service (Phase 13): Python, FastAPI, Pandas, NumPy, scikit-learn, RapidFuzz, PostgreSQL with pgvector, MongoDB time series. It never touches MSSQL. It reads data through secured read-only core endpoints.
- Infrastructure: Docker, Docker Compose, Nginx, seed SQL.
- Frontend mounts under /foms/*. Reuse existing shared components (DashboardLayoutShell, DashboardLayout, Sidebar, GlobalHeader, DataTable, TextField, SelectField, TextareaField, CalendarPicker, CalendarRangePicker, StatusBadge, ConfirmModal, toasts). Create missing ones in the shared components folder following Design System v2.0: no gradients, no solid badges, no spinners (use skeletons), no icon-only buttons without a text label or tooltip, no developer wording in UI text.

## Backend rules
- API prefix /api/foms/v1. Return RFC 7807 ProblemDetails with a stable machine code and a specific human message (for example DUPLICATE_WAYBILL: Waybill 123 already exists, AMOUNT_MISMATCH: Payment 1,000.00 does not equal invoice 1,050.00, MISSING_RATE: No effective rate for client X, area NCR on 2026-11-05).
- Authorization by policy codes from docs/FOMS_RULES.md section 10, enforced on the API, never only in the UI. Anonymous access to anything except health and login callback is a bug.
- Money: decimal(18,2) columns, one Money helper, no double or float anywhere in domain or DTOs.
- Each business operation that changes several tables runs in ONE database transaction (unit of work). Posting a journal entry, updating statuses and writing the audit row succeed or fail together.
- Concurrency: rowversion on invoices, payments, budget lines, periods. Handle conflicts with a clear 409.
- Audit: an EF SaveChanges interceptor writes AuditLog rows for every create, update, delete-attempt and explicit action, with before and after JSON. The AuditLog table is append-only (database trigger blocks UPDATE and DELETE).
- Soft state, no hard delete of financial records. Use status or IsArchived.
- File uploads: only PDF, JPG, PNG (proofs, receipts, PODs) and CSV or XLSX (imports), max 10 MB, stored outside the web root with a generated name, checked by content type and signature, access through an authorized download endpoint only.
- Settings live in a Settings table with typed values, edited on the Settings page, each change audited.
- Seed data: a seed command creates one user per role, departments, categories, one demo client with the Section 4 test rates, and settings. Seed is idempotent. Demo data is clearly marked and can be removed.
- Every list endpoint supports paging, sorting and filters used by the DataTable.

## Frontend rules
- TypeScript strict. No any without a comment. API client is a thin fetch wrapper that reads VITE_FOMS_API_URL, attaches the token, maps ProblemDetails to toasts and field errors.
- Pages show loading skeleton, empty state and error state. Forms validate before submit and show specific messages.
- Role-based navigation: hide what the role cannot use, and still handle 403 from the API.
- Dates shown in Philippines time (Asia/Manila), stored in UTC. Currency shown as PHP with thousands separators and 2 decimals.
- Print and export views must match the screen with the same filters.

## Testing rules
- Backend: xUnit unit tests for every business rule and a test per acceptance check of the phase. Integration tests with a real SQL Server container or LocalDB for transactions and triggers. Use the Section 4 test vector wherever billing is computed.
- Frontend: TypeScript typecheck, ESLint zero errors, Playwright tests for the phase's main flows, one per role that uses the screens.
- A phase is DONE only when: solution builds, all backend tests pass, frontend typecheck and lint pass, Playwright tests for the phase pass, no TODO, no placeholder screens, no console errors in Playwright runs.

## Phase protocol (every phase prompt ends by pointing here)
1. Read docs/FOMS_RULES.md, docs/ENGINEERING.md, docs/PHASES.md and every file in docs/handoff/ before touching code. Find build, test, lint and run commands (package.json, README, Makefile, docker-compose) and record them in the Commands section below if missing.
2. Preconditions: run build and tests first. If something from an earlier phase is missing or broken, fix it with the smallest possible change, write it under "Gaps fixed" in this phase's handoff file, and continue. Do not stop to ask.
3. Build ONLY the listed scope. No unrelated refactors, no features from later phases, no renaming of earlier-phase APIs. If an earlier handoff defines a name, use that exact name.
4. Backend, frontend, tests, seed data and migrations are all part of the phase. Create EF migrations with clear names. Never edit an applied migration.
5. Run the full checks listed under Testing rules. Fix failures until green.
6. Write docs/handoff/phase-N.md with: summary, tables and migrations, endpoints with policy codes, screens and routes, settings keys, seed data, events and ledger postings added, tests added and results, commands, Gaps fixed, Known limits (must be empty or justified).
7. Print a short summary and STOP. Do not start the next phase.

## Commands

> All commands assume the working directory is the repo root:
> `FOMS-System-Repository-develop/FOMS-System-Repository-develop/`
>
> Results distinguish the original Phase 1 baseline report from checks rerun in the current continuation. The worktree has pre-existing uncommitted Phase 2 edits; no application files were changed here.

### Environment / Runtime

| Tool | Version confirmed | Command |
|------|------------------|---------|
| .NET | 10.0.101 installed; projects target **net9.0** | `dotnet --info` → PASSED |
| Node.js / npm | 24.11.1 / 11.14.1 | `node --version`, `npm --version` → PASSED |
| SQL Server | localhost\SQLEXPRESS (alias joo\SQLEXPRESS) | requires `-C` (TrustServerCertificate) flag |

### Backend

```
# Build — individual projects (root FOMS.sln fails without network NuGet restore)
cd foms-backend/FOMS.Domain
dotnet build -nodereuse:false -maxcpucount:1
# → PASSED on serial rerun (NuGet vulnerability-feed warning only)

cd foms-backend/FOMS.Application
dotnet build -nodereuse:false -maxcpucount:1
# → FAILED: pre-existing worktree syntax error CommandValidators.cs(349,2), CS1513

cd foms-backend/FOMS.Infrastructure
dotnet build -nodereuse:false -maxcpucount:1
# → FAILED: same Application compile error

cd foms-backend/FOMS.Api
dotnet build -nodereuse:false -maxcpucount:1
# → FAILED: same Application compile error

# Tests (current suite uses EF InMemory test databases)
cd foms-backend/FOMS.Tests
dotnet test --no-restore
# → FAILED before test execution: same CommandValidators.cs(349,2) CS1513 compile error

# Run API locally
cd foms-backend/FOMS.Api
dotnet run
# NOT RUN: startup calls ApplicationDbContext.Database.MigrateAsync(); prohibited in this read-only phase.
# Configured local URL is http://localhost:5007 (ASPNETCORE_URLS).

# EF migration (schema-writing; prohibited in Phase 1)
cd foms-backend/FOMS.Infrastructure
dotnet ef database update --startup-project ../FOMS.Api
# NOT RUN. The live database reports 15 rows in __EFMigrationsHistory; no migration was executed here.

# Seed
# No standalone seed command is configured. ApplicationDbContextSeed is used by tests with EF InMemory.
# NOT RUN against FOMS_DB; seeding would write data.
```

### Frontend

```
# Install (requires network — run outside sandbox)
cd foms-frontend
npm install
# → PASSED in the earlier Phase 1 run (344 packages added); not repeated because dependencies are already installed.

# Development server
npm run dev
# → PASSED in current continuation; GET http://127.0.0.1:5173/ returned HTTP 200

# Production build
npm run build
# → PASSED (TypeScript check + Vite build, 2773 modules transformed; chunk-size and import warnings)

# Preview production build
npm run preview
# → PASSED in current continuation; GET http://127.0.0.1:4173/ returned HTTP 200

# Lint
npm run lint
# → PASSED in current continuation

# Tests (vitest)
npm test
# → FAILED: 92 passed, 21 failed across 5 files; emp001Flow.test.tsx cannot import deleted SpeedPayValidation.
#   Other failures include duplicateDetection, postLoginRedirect, dashboardAndSidebar and fmDataSync.
```

### SpeedPay Portal (REMOVE in Phase 2)

```
# speedpay-portal/ — separate Vite app, dev port 5174
# DO NOT run; scheduled for removal in Phase 2
```

### Docker Compose

```
# File location
FOMS-System-Repository-develop/docker-compose.yml

# Validate config (sandbox-safe)
docker compose -f docker-compose.yml config
# → PASSED (`--quiet`)

# Build API image (no service startup)
docker compose build foms-api
# → FAILED: same pre-existing CommandValidators.cs(349,2) CS1513 compile error

# Start all services (requires Docker Desktop — run outside sandbox)
docker compose -f docker-compose.yml up -d
# NOT RUN: API startup automatically invokes EF migrations; also starts persistent database services.

# Stop
docker compose -f docker-compose.yml down
# NOT RUN: would stop any existing compose services and may affect shared data.
```

### Database (SQL Server)

```
# Connect
sqlcmd -S "localhost\SQLEXPRESS" -d FOMS_DB -C -E
# → Connected                         [PASSED — requires SQL Server access]

# Backup (run outside sandbox — requires SQL Server file permissions)
powershell -ExecutionPolicy Bypass -File scripts/backup-db.ps1
# Run in current continuation: backups/FOMS_DB_backup_20261105_190740_826.bak (14,602,240 bytes)
# RESTORE VERIFYONLY → PASSED; SHA256 07BB938B6DEA94E4C48F3FF15155DA95617815BF7B0AB0145E7501173EF5860D; no restore was performed

# Rollback — NEVER run against live database
# Test-restore only:
powershell -ExecutionPolicy Bypass -File scripts/rollback-db.ps1 \
  -BackupFile backups/FOMS_DB_backup_20261105_190740_826.bak \
  -TargetDatabase FOMS_DB_RESTORE_TEST
# NOT RUN; rollback was not executed in this phase.
```

### Command Coverage and Safety Exceptions

| Area | Install/restore | Build | Test | Lint | Run | Migrate | Seed |
|------|-----------------|-------|------|------|-----|---------|------|
| Backend | `dotnet restore .\FOMS.sln --ignore-failed-sources` → PASSED (cached packages; NU1900 feed warning) | Individual project results above | `dotnet test --no-restore` → FAILED at compile | No backend linter configured (N/A) | `dotnet run` not run because startup migrates | `dotnet ef database update` not run; schema writes explicitly prohibited | No seed CLI; no DB seed run |
| Frontend | `npm install` → PASSED in earlier Phase 1 run; not repeated | `npm run build` → PASSED | `npm test` → FAILED (92/21) | `npm run lint` → PASSED | `npm run dev`, `npm run preview` → PASSED (HTTP 200) | N/A | N/A |
| Docker Compose | N/A | `docker compose build foms-api` → FAILED at compile | No compose test command configured (N/A) | N/A | `docker compose up/down` not run because of persistent service/data effects | No compose migration command; API startup migrates automatically | No compose seed command |

Commands marked NOT RUN were deliberately not executed because they could alter schema/data or affect shared running services. Do not interpret them as passing.

### Ports and Environment Variables

| Service | Local Port | Docker Port |
|---------|-----------|-------------|
| FOMS Backend API | 5007 | 8080 |
| Frontend (dev) | 5173 | — |
| Frontend (preview) | 4173 | — |
| Legacy SpeedPay portal (dev) | 5174 | — |
| PostgreSQL | — | 5432 |
| MongoDB | — | 27017 |
| pgAdmin | — | 5050 |

Key environment variables (from `.env.example`):

| Variable | Purpose |
|----------|---------|
| `ASPNETCORE_ENVIRONMENT` | ASP.NET Core environment (Development in local template/Compose) |
| `ASPNETCORE_URLS` | Backend listen address (default `http://localhost:5007`) |
| `ConnectionStrings__DefaultConnection` | Default EF Core database connection |
| `ConnectionStrings__FomsSqlServer` | SQL Server connection for FomsDbContext |
| `MSSQL_SERVER`, `MSSQL_DATABASE`, `MSSQL_CONNECTION_STRING` | Local SQL Server settings |
| `FOMS_API_URL` | Backend URL consumed by frontend |
| `VITE_FOMS_API_URL` | Frontend env var for the API |
| `VITE_API_URL` | Legacy frontend API URL setting in `.env.example` |
| `JWT_SECRET`, `JWT_ISSUER`, `JWT_AUDIENCE` | JWT signing and validation settings |
| `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DATABASE`, `POSTGRES_USER`, `POSTGRES_PASSWORD` | AI output store configuration |
| `MONGODB_URI`, `MONGODB_DATABASE`, `MONGO_DB` | AI telemetry/trends store configuration |
| `GEMINI_API_KEY`, `AI_MODEL_NAME`, `AI_SERVICE_URL`, `AI_SERVICE_API_KEY` | AI provider/service configuration |
| `STARS_BASE_URL`, `STARS_API_KEY` | STARS integration settings, if configured in the local environment |
| `MAX_UPLOAD_SIZE_MB`, `ALLOWED_FILE_TYPES` | Upload validation settings |
| `ENABLE_SPEEDPAY`, `VITE_SPEEDPAY_API_URL`, `SPEEDPAY_API_BASE_URL` | Legacy SpeedPay settings; remove per §1 after owner approval |
| `PAYMONGO_PUBLIC_KEY` | **TO REMOVE** — SpeedPay/PayMongo out of scope |
| `PAYMONGO_SECRET_KEY` | **TO REMOVE** — SpeedPay/PayMongo out of scope |
| `VITE_PAYMONGO_PUBLIC_KEY` | **TO REMOVE** — SpeedPay/PayMongo out of scope |
