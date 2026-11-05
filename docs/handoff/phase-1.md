# Phase 1 Handoff — Audit and Safety Net (MIG-01, MIG-02)

**Branch:** `feature/foms-phase-1`  
**Date:** 2026-11-05  
**Status:** Deliverables completed — READ-ONLY phase. No application source files were changed during this continuation; the worktree already contained unrelated uncommitted Phase 2 edits.

---

## Summary

Phase 1 is a pure audit and safety-net phase. No production code was added, edited, or deleted. The deliverables are:

1. **`docs/AUDIT.md`** — full system inventory with KEEP/REWORK/REMOVE verdicts and all 19 legacy checks (FOUND/NOT FOUND).
2. **`docs/ENGINEERING.md`** — Commands section filled with every build, test, lint, run, migrate, seed and Docker command, all tried and noted.
3. **`docs/ROLLBACK.md`** — backup procedure with the actual backup file path and SHA256.
4. **`scripts/backup-db`**, **`scripts/backup-db.ps1`**, **`scripts/rollback-db`**, and **`scripts/rollback-db.ps1`** — database backup and isolated restore scripts.
5. **`backups/FOMS_DB_backup_20261105_190740_826.bak`** — timestamped safety backup (14,602,240 bytes / 13.93 MB), verified with `RESTORE VERIFYONLY`.

---

## Tables and Migrations

No new tables or migrations were created in this phase.

**Existing state at phase start:**
- **82 tables** in the live `FOMS_DB` snapshot (SQL Server / `localhost\SQLEXPRESS`); see the complete table-by-table census in `docs/AUDIT.md §c`.
- **15 EF Core migrations** applied (tracked in `__EFMigrationsHistory`).
- Two EF DbContexts: `ApplicationDbContext` (PostgreSQL, EF migrations in `FOMS.Infrastructure/Migrations/`) and `FomsDbContext` (SQL Server, `FomsMssqlEntities.cs`).

**No schema changes were made or migrations run.** The current live database metadata differs from the original audit in places and is marked as a mixed/indeterminate dataset; do not treat it as disposable.

---

## Endpoints with Policy Codes

No endpoints were added or changed. See `docs/AUDIT.md §b` for the full controller inventory.

**Controllers with missing authorization (REWORK — pending approval):**
`AiCollectionController`, `AiDataController`, `AiDuplicatesController`, `AiFeaturesController`, `AiOutputsController`, `CashAdvancesController`, `ClientsController`, `DmsIntegrationController`, `IntegrationController`, `LogsController`, `TicketsController`, `ValidationsController`.

**Controllers to remove (pending approval):**
`PaymongoWebhookController`, `SpeedPayController`, `SpeedPaySharedController`, `SpeedPaySubmissionsController`, `TestDataController`.

---

## Screens and Routes

No screens or routes were added or changed. See `docs/AUDIT.md §a` for the full route inventory.

**Routes to remove (pending approval):**
- `/speedpay` (App.tsx) — client portal, out of scope.
- `/speedpay-validation` and `/speedpay-validation/:id` (MODULES) — SpeedPay validation queue.
- `speedpay-portal/` entire directory — separate Vite app.

**Routes to fix (pending approval):**
- `rates` (`/rate-configuration`) — `roles: {}` empty; no roles can access.
- `waybills` (`/waybills`) — `roles: {}` empty; no roles can access.
- `cashAdvancePortal` (`/cash-advance-portal`) — `roles: {}` orphaned route.

---

## Settings Keys

No settings were added or changed.

**Existing settings noted:**
- `DueSoonDays` default 7 — referenced in `docs/FOMS_RULES.md §3`.
- No `Settings` table found in `FOMS_DB` (gap — will need to be created in Phase 3+).

---

## Seed Data

No seed data was added or changed.

**Seed state:** There is no standalone backend seed CLI. The live database contains test-labeled and sequential employee accounts, branded client names, and business rows; classify it as mixed/indeterminate and preserve all data. `ApplicationDbContextSeed.SeedSampleDataAsync()` is referenced by EF InMemory tests; it was not run against `FOMS_DB`.

---

## Events and Ledger Postings Added

None — read-only phase.

---

## Tests Added and Results

No tests were added in this phase.

**Pre-existing test state at phase start:**

| Suite | Tool | Result |
|-------|------|--------|
| Backend Domain build | `dotnet build` | PASSED (serial rerun) |
| Backend Application / Infrastructure / API build | `dotnet build` | FAILED at pre-existing worktree `CommandValidators.cs(349,2)` — CS1513 |
| Backend tests | `dotnet test --no-restore` | FAILED before test execution due to the same compile error |
| Frontend build/typecheck | `npm run build` | PASSED; TypeScript check and Vite build (2773 modules; warnings) |
| Frontend unit | Vitest | 92 PASSED, 21 FAILED in 5 files (current worktree) |
| Frontend lint | ESLint | PASSED in current continuation |
| Frontend dev/preview | HTTP smoke checks | Both returned HTTP 200 |
| Docker Compose config | `docker compose config --quiet` | PASSED |
| Docker API image | `docker compose build foms-api` | FAILED at the same `CommandValidators.cs` CS1513 |
| SQL backup | `scripts/backup-db.ps1` | PASSED; timestamped file produced; `RESTORE VERIFYONLY` passed |
| SQL migration / API startup / seed | N/A for execution | NOT RUN to preserve the read-only/no-schema-write requirement |

The current build/test results are against the pre-existing modified worktree; they are not attributed to this Phase 1 documentation/safety-script work.

---

## Commands

See **`docs/ENGINEERING.md → Commands`** for the full list. Quick reference:

```bash
# Backend build (per project)
cd foms-backend/FOMS.Domain && dotnet build -nodereuse:false -maxcpucount:1

# Backend tests (outside sandbox — needs SQL Server)
cd foms-backend/FOMS.Tests && dotnet test --no-restore
# Result: FAILED before tests ran; pre-existing CommandValidators.cs(349,2) CS1513

# Frontend install (outside sandbox — needs network)
cd foms-frontend && npm install

# Frontend build
cd foms-frontend && npm run build
# Result: SUCCEEDED (2773 modules transformed)

# Frontend lint
cd foms-frontend && npm run lint
# Result: PASSED in the current continuation

# Docker config validate
docker compose -f docker-compose.yml config
# Result: SUCCEEDED

# Backup
powershell -ExecutionPolicy Bypass -File scripts/backup-db.ps1
# Result: backups/FOMS_DB_backup_20261105_190740_826.bak (14,602,240 bytes)
# RESTORE VERIFYONLY: PASSED; SHA256 07BB938B6DEA94E4C48F3FF15155DA95617815BF7B0AB0145E7501173EF5860D
```

---

## Gaps Fixed

None — this is a read-only phase. No application source files were modified.

---

## Known Limits

| Limit | Justification |
|-------|---------------|
| Backend solution build/test and Docker image build fail | The worktree has pre-existing Phase 2 edits; `CommandValidators.cs(349,2)` reports CS1513. Application code was not edited in this read-only phase. |
| Frontend tests have 21 failures | Current worktree test failures are recorded in `docs/ENGINEERING.md`; no application code was changed to address them. |
| No float/real database columns in current SQL snapshot | Legacy check #8 also records the hard-coded DMS rate path and typed-rate/bare-total concerns; any rework requires owner approval. |
| SpeedPay remnants still present | REMOVE flagged in AUDIT.md. Pending owner approval. No code deleted in this read-only phase. |
| `FinanceManager` role name mismatch (DB display name: "Financial Manager") | REWORK flagged. Pending owner approval. |
| Anonymous controllers (12 found) | REWORK flagged. Pending owner approval. |
| Data set is mixed/indeterminate | Names and row volumes look test-like but branded clients and non-test names prevent treating it as disposable; preserve data pending owner confirmation. |
| `AccountingPeriod` / period-close not implemented | Phase 11 scope. Not a Phase 1 gap. |
| DueDate computed from creation time instead of received date (DMS path, InvoicesController) | REWORK flagged check #12. Pending owner approval. |
| Outflow posted at liquidation instead of release | REWORK flagged check #10. Pending owner approval. |
