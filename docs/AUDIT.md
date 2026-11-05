# FOMS Phase 1 Audit — MIG-01, MIG-02

**Branch:** `feature/foms-phase-1`  
**Auditor:** Phase 1 automated inventory  
**Date:** 2026-11-05  
**Repo root:** `FOMS-System-Repository-develop/FOMS-System-Repository-develop/`

**Scope note:** Application findings describe the Phase 1 baseline at commit `67e318b`. The worktree already contains unrelated, uncommitted Phase 2 application changes; they were not edited in this phase. SQL Server metadata and row counts below were read live on 2026-11-05 and may therefore reflect a later database state. No migration or database write was performed for this audit.

---

## a. Frontend Pages and Routes

Source of truth: `foms-frontend/src/utils/roleAccess.ts` MODULES array + `App.tsx`.

### Protected Routes (from MODULES)

| Key | Path | Detail Path | Roles (view) | Verdict | Reason |
|-----|------|-------------|--------------|---------|--------|
| dashboard | /dashboard | — | FM, HA, ACC, AFM | KEEP | Required §10 |
| approvals | /approvals | — | AFM | KEEP | Required §10 |
| escalatedApprovals | /escalated-approvals | — | FM | KEEP | Required §10 |
| clients | /clients | /clients/:id | ACC, FM | KEEP | Required §4 |
| rates | /rate-configuration | /rate-configuration/:id | (empty roles) | REWORK | No roles assigned — route unreachable; needs FM/HA roles per §10 |
| waybills | /waybills | /waybills/:id | (empty roles) | REWORK | No roles assigned — route unreachable; needs ACC/HA roles per §10 |
| invoiceCreate | /invoice-create | — | ACC | KEEP | Required §10 |
| invoicingDesk | /invoicing-desk | /invoicing-desk/:id | ACC, HA, FM | KEEP | Required §10 |
| billingValidation | /billing-validation | — | ACC, HA, FM | KEEP | Required §10 |
| dmsIntake | /dms-billing-intake | — | ACC, HA, AFM | KEEP | Required §5 |
| invoiceReview | /invoice-review | /invoice-review/:id | HA, FM | KEEP | Required §10 |
| accountsReceivable | /accounts-receivable | /accounts-receivable/:id | ACC, HA, FM | KEEP | Required §7 |
| starsCollection | /stars-collection | — | ACC, HA, AFM, FM | KEEP | Required §7 |
| payments | /payments | /payments/:id | ACC, HA, FM | KEEP | Required §8 |
| speedpayValidation | /speedpay-validation | /speedpay-validation/:id | ACC, HA, FM | REMOVE | SpeedPay is out of scope per §1 |
| receipts | /receipts | /receipts/:id | ACC, FM | REWORK | Official Receipt as separate generated document is legacy check #11; page KEEP but generation flow needs rework |
| settlements | /settlements | — | ACC, HA, FM | KEEP | Required §8 |
| recordSettlement | /record-settlement | — | ACC, HA | KEEP | Required §8 |
| adjustments | /adjustments | — | ACC, HA, FM | KEEP | Required §8 |
| myCashAdvances | /my-cash-advances | — | ACC | KEEP | Required §10 |
| cashAdvancePortal | /cash-advance-portal | — | (empty roles) | REMOVE | Orphaned route — no roles; functionality merged into /approvals |
| liquidations | /liquidations | /liquidations/:id | AFM, FM | KEEP | Required §10 |
| cashFlow | /cash-flow | — | FM | KEEP | Required §9/10 |
| duplicateScan | /duplicate-scan | — | ACC, AFM | KEEP | Required §13 |
| mySubmissions | /my-submissions | — | ACC, AFM | KEEP | Required §13 |
| manualReviewQueue | /manual-review-queue | — | FM, HA | KEEP | Required §13 |
| uniqueDocuments | /unique-documents | — | FM, HA, ACC, AFM | KEEP | Required §13 |
| flaggedDuplicates | /flagged-duplicates | — | FM, HA, ACC, AFM | KEEP | Required §13 |
| reviewHistory | /review-history | — | FM, HA, ACC, AFM | KEEP | Required §13 |
| documentExtraction | /document-extraction | — | ACC, AFM | KEEP | Required §13 |
| forReview | /for-review | — | HA, FM | KEEP | Required §10 |
| reports | /reports | /reports/:id | FM, HA, ACC, AFM | KEEP | Required §12 |
| auditLogs | /audit-logs | — | HA, FM | KEEP | Required §10 |
| aiHistory | /ai-history | — | FM, HA, ACC, AFM | KEEP | Required §13 |
| profile | /profile | — | all | KEEP | Required §10 |
| notifications | /notifications | — | all | KEEP | Required §10 |

### Public / Unprotected Routes (App.tsx)

| Path | Component | Verdict | Reason |
|------|-----------|---------|--------|
| /login | LoginPage | KEEP | Required |
| /speedpay | SpeedPay | REMOVE | SpeedPay is out of scope per §1 — no client portal |
| /ai/output-history | Redirect → /ai-history | KEEP | Harmless redirect |

### Design System Conformance

| Issue | Files | Verdict |
|-------|-------|---------|
| `linear-gradient` CSS (non-solid backgrounds) | Dashboard.tsx, SpeedPay.tsx, BillingValidation.tsx, StarsCollection.tsx, Settlements.tsx, Reports.tsx, AuditLogs.tsx, Liquidations.tsx, CashFlow.tsx, DmsIntake.tsx (~10 files) | REWORK — Rule §9: use solid color tokens only |
| `LoadingSpinner` component used instead of skeleton loaders | 7 page files including Dashboard.tsx, Payments.tsx, Invoicing.tsx | REWORK — Rule §9: use skeleton pattern for content loading |
| Tailwind utility framework/directives | No Tailwind dependency, configuration, or `@tailwind` directive found; custom CSS class names are used | KEEP — ENGINEERING.md Stack requires Vanilla CSS and explicitly prohibits Tailwind |
| Solid status badges | Solid badge styles found in status components/pages (baseline UI inventory) | REWORK — ENGINEERING.md Stack requires non-solid badges using design tokens |
| `axios` in package.json | foms-frontend/package.json | REWORK — Rule §9: use `fetch`; no third-party HTTP client |
| Icon-only buttons without aria-label | Multiple pages (not exhaustively enumerated) | REWORK — Rule §9: accessibility requirement |
| Developer wording ("EMP-004", "Financial Manager Test User") visible in fallback labels | Multiple controllers returning test strings as defaults | REWORK — Rule §9: no developer wording in production UI |

---

## b. Backend Projects, Controllers and Endpoints

### Projects

| Project | Framework | Current-worktree result | Verdict |
|---------|-----------|--------------|---------|
| FOMS.Domain | net9.0 | SUCCEEDED (2 warnings) | KEEP |
| FOMS.Application | net9.0 | FAILED — pre-existing worktree syntax error `CommandValidators.cs(349,2)`, CS1513 | KEEP |
| FOMS.Infrastructure | net9.0 | FAILED — same Application compile error | KEEP |
| FOMS.Api | net9.0 | FAILED — same Application compile error | KEEP |
| FOMS.Tests | net9.0 | FAILED before test execution — same Application compile error | KEEP |

> Build results above are from the current worktree, which already contains unrelated uncommitted Phase 2 edits. They are not attributed to Phase 1. The source inventory remains scoped to baseline commit `67e318b`. Root `FOMS.sln` solution build also fails due to NuGet vulnerability-feed network access. Target framework is net9.0, not net10.0 (spec §3 says net10 — gap for Phase 3).

### Controllers and Authorization

| Controller | Route | Authorization | Verdict | Reason |
|------------|-------|---------------|---------|--------|
| AccountantController | api/accountant | [Authorize] | KEEP | Correct |
| AiCollectionController | api/ai/collection | **[AllowAnonymous]** | REWORK | Missing auth — FOMS_RULES §10 |
| AiDataController | api/ai/data | **[AllowAnonymous]** | REWORK | Missing auth — FOMS_RULES §10 |
| AiDuplicatesController | api/ai/duplicates | **[AllowAnonymous]** | REWORK | Missing auth — FOMS_RULES §10 |
| AiFeaturesController | api/ai/features | **[AllowAnonymous]** | REWORK | Missing auth — FOMS_RULES §10 |
| AiOutputsController | api/ai/outputs | **[AllowAnonymous]** | REWORK | Missing auth — FOMS_RULES §10 |
| ApprovalsController | api/approvals | [Authorize] plus anonymous action marker | REWORK | Review public workflow actions against role matrix §10 |
| AssistantFinanceManagerController | api/assistant-finance-manager | [Authorize] | KEEP | Correct |
| AuditLogsController | api/audit-logs | [Authorize] | KEEP | Append-only audit records required by §9 |
| CashAdvancesController | api/cash-advances | **[AllowAnonymous]** | REWORK | Missing auth — FOMS_RULES §10 |
| CashFlowController | api/cash-flow | [Authorize] | KEEP | Correct |
| CashOutflowsController | api/cash-outflows | [Authorize] | KEEP | Correct |
| ClientsController | api/clients | **[AllowAnonymous]** | REWORK | Missing auth — §10; client data is sensitive |
| DmsIntegrationController | api/integration/dms | **[AllowAnonymous]** | REWORK | Needs API-key or service auth per §6 |
| ExecutiveDashboardController | api/executive-dashboard | [Authorize] | KEEP | Correct |
| FinancePaymentsController | api | Anonymous action marker found | REWORK | Payment validation/rejection routes require FinanceManager-only control under §§5/10 |
| FinancialManagerController | api/financial-manager | [Authorize] | KEEP | Correct |
| HeadAccountantController | api/head-accountant | [Authorize] | KEEP | Correct |
| IntegrationController | api/integration | **[AllowAnonymous]** | REWORK | Needs API-key auth for external callers |
| InvoicesController | api/invoices | [Authorize] plus anonymous action marker | REWORK | Review every action authorization under §10; approved-invoice edit issue also appears in check #7 |
| LiquidationsController | api/liquidations | [Authorize] plus anonymous action marker | REWORK | Review every action authorization under §10 |
| LogsController | api/logs | **[AllowAnonymous]** | REWORK | Audit logs must not be publicly readable — §10 |
| OfficialReceiptsController | api/official-receipts | [Authorize] | REWORK | See legacy check #11 |
| PaymentsController | api/payments | [Authorize] | KEEP | Correct |
| PaymongoWebhookController | api/paymongo-webhook | **[AllowAnonymous]** | REMOVE | SpeedPay/PayMongo out of scope — §1 |
| ReceivablesController | api/receivables | [Authorize] | KEEP | Correct |
| ReportsController | api/reports | [Authorize] | KEEP | Correct |
| SettlementsController | api/settlements | [Authorize] | KEEP | Correct |
| SpeedPayController | api/speedpay | **[AllowAnonymous]** | REMOVE | SpeedPay out of scope — §1 |
| SpeedPaySharedController | api/speedpay-shared | **[AllowAnonymous]** | REMOVE | SpeedPay out of scope — §1 |
| SpeedPaySubmissionsController | api/speedpay/submissions | **No controller policy** | REMOVE | SpeedPay out of scope — §1 |
| TestDataController | api/test-data | [Authorize] | REMOVE | Test/seed controller should not exist in production |
| TicketsController | api/tickets | **[AllowAnonymous]** | REWORK | Needs auth — §10 |
| ValidationsController | api/validations | **[AllowAnonymous]** | REWORK | Needs auth — §10 |

### HTTP Action Methods and Route Templates

The following inventory records the HTTP verb and action route template for each controller found at baseline commit `67e318b`. Compose an action template with its controller route prefix shown above or in this source-attribute scan; `(base)` means the controller prefix itself. `Authorize (no named policy)` means authentication is required but no named §10 role policy was found. `AllowAnonymous` records an anonymous marker in the controller/action attributes; `NO controller policy` means no controller-level authorization policy was declared. Endpoint-specific `[AllowAnonymous]` overrides apply only to the marked action. These tags are authorization evidence, not a claim that the full §10 permission matrix is implemented; see §d. The controller verdict matrix above identifies KEEP/REWORK/REMOVE; public login/SSO routes are expected, but other anonymous finance/data actions require rule-based review.

```text
Controller | Route prefixes | Authorization evidence | HTTP method + action route templates
AccountantController | api/accountant, accountant | Authorize (no named policy) | GET dashboard; GET clients; GET invoices/eligible-clients; POST invoices/create; GET invoices; GET billing-validation; POST billing-validation/{id}/submit; POST billing-validation/{id}/return; GET accounts-receivable; GET payments; POST payments/record; GET payments/history/{invoiceId}; GET speedpay-validation; GET official-receipts; GET settlements; GET record-settlement; POST record-settlement; GET financial-adjustments; POST financial-adjustments; POST ai/duplicate-scan; GET ai/unique-documents; GET ai/flagged-duplicates; GET review-history; POST ai/document-extraction; GET ai/document-extraction/history; POST reports/generate; GET ai/output-history
AccountingController | api | Authorize (no named policy) | GET chart-of-accounts; GET general-ledger; POST journal-entries; GET trial-balance
ActivityLogsController | api/activity-logs | Authorize (no named policy) | GET (base)
AdjustmentsController | api/adjustments, api/v1/adjustments, adjustments | Authorize (no named policy) | GET (base); POST (base); PUT {id}/approve; POST {id}/approve; PUT {id}/reject; POST {id}/reject; DELETE {id}
AiCollectionController | (no class route prefix) | AllowAnonymous | GET api/ai/collection/recommendations; GET ai/collection/recommendations; POST api/ai/collection/recommendations/{id}/review; POST ai/collection/recommendations/{id}/review; POST api/ai/collection/recommendations/{id}/escalate; POST ai/collection/recommendations/{id}/escalate; POST api/ai/collection/recommendations/escalate; POST ai/collection/recommendations/escalate; POST api/ai/collection/recommendations/new; POST ai/collection/recommendations/new; POST api/ai/collection/recommendations; POST ai/collection/recommendations; GET api/ai/collection/priorities; GET ai/collection/priorities; GET api/ai/dashboard/alerts; GET ai/dashboard/alerts
AiDataController | api/ai-data | AllowAnonymous | GET waybills; GET invoices; GET official-receipts; GET speedpay-submissions; GET accounts-receivable; GET aging; GET payments; GET collection-history
AiDuplicatesController | api/ai/duplicates, api/duplicates, ai/duplicates, duplicates | AllowAnonymous | GET (base); GET flagged; GET unique-documents; GET review-history; POST validate; POST /api/ai/documents/validate; POST /ai/documents/validate; POST scan; POST /api/ai/documents/scan; POST {id}/decide; POST {id}/review; POST check; POST skip-log; GET scan-logs; DELETE {id}; DELETE review-history/{id}; POST /api/ai/duplicate-scan; POST /ai/duplicate-scan; POST /api/ai/alerts/{id}/submit; POST /ai/alerts/{id}/submit; POST /api/ai/alerts/{id}/decision; POST /ai/alerts/{id}/decision; POST /api/ai/documents/confirm-unique; POST /ai/documents/confirm-unique
AiFeaturesController | api/ai | AllowAnonymous | GET collection/suggestions; POST collection/decision; GET risk/score; POST documents/upload; GET documents; GET documents/{id}; POST documents/{id}/confirm
AiOutputsController | api/ai/outputs, api/ai-outputs, ai/outputs, ai-outputs | NO controller policy | GET (base); GET {id}; POST (base)
AnalyticsController | api/analytics, api/v1/analytics | Authorize (no named policy) | GET (base); GET metrics; GET predictions
ApprovalsController | api/approvals, approvals | AllowAnonymous marker found | GET pending; GET {id}; GET {id}/history; POST {id}/approve; POST {id}/reject; POST {id}/return; POST {id}/escalate; POST {entityType}/{id}/submit; GET counts
AssistantFinanceManagerController | api/assistant-finance-manager, assistant-finance-manager | Authorize (no named policy) | GET dashboard; GET liquidations; GET liquidations/{id}; POST liquidations/submit; POST liquidations/{id}/review; POST liquidations/{id}/return; POST liquidations/{id}/endorse; DELETE liquidations/{id}; POST ai/duplicate-scan; GET ai/duplicate-scan/history; GET ai/scan-status/{scanId}; POST ai/document-extraction; GET ai/unique-documents; GET ai/unique-documents/{recordId}; GET ai/flagged-duplicates; GET ai/flagged-duplicates/{alertId}; POST ai/flagged-duplicates/{alertId}/mark-duplicate; POST ai/flagged-duplicates/{alertId}/mark-unique; POST ai/flagged-duplicates/{alertId}/return-for-review; POST ai/flagged-duplicates/{alertId}/endorse; GET review-history; DELETE ai/review-history/{id}; POST reports/generate; GET ai/output-history
AuditLogsController | api/audit-logs, api/v1/audit-logs, audit-logs | Authorize (no named policy) | GET (base); POST (base)
AuditLogsTestController | api/test | NO controller policy | GET audit-logs; POST audit-logs
AuthController | api/auth, auth | AllowAnonymous marker found | POST login; POST sso-exchange; POST logout; POST refresh; GET me; POST change-password; POST unlock/{userId}
BankAdviceController | api/bank-advice | Authorize (no named policy) | GET (base); POST (base)
BillingRatesController | api/billing-rates, api/v1/billing-rates, billing-rates | Authorize (no named policy) | GET (base); GET {id}; POST (base); PUT {id}; DELETE {id}
BillingRecordsController | api/billing-records, api/v1/billing-records, billing-records | Authorize (no named policy) | GET (base); GET {id}; POST (base); POST {id}/{actionName}; PUT {id}
CashAdvancesController | api/cash-advances, api/v1/cash-advances, cash-advances | AllowAnonymous | GET (base); GET mine; POST (base); PUT {id}; GET {id}; POST {id}/approve; POST {id}/disburse
CashFlowController | api/cash-flow, api/v1/cashflow, api/v1/cash-flow, cash-flow | Authorize (no named policy) | GET (base); GET summary; GET balances; POST (base)
CashOutflowsController | api/cash-outflows, cash-outflows | Authorize (no named policy) | POST (base); GET (base); GET {id}; GET assistant/pending; POST {id}/assistant/approve; POST {id}/assistant/reject; POST {id}/assistant/return; POST {id}/assistant/escalate
ClientsController | api/clients, api/v1/clients, clients, client-accounts, api/client-accounts, api/v1/client-accounts | NO controller policy | GET lookup/{clientCode}; POST portal-login; GET (base); GET {id}; POST (base); DELETE {id}; PUT {id}/archive; PUT {id}
DashboardController | api/dashboard, dashboard | Authorize (no named policy) | GET summary; GET collections; GET receivables; GET cash-flow; GET accounting; GET payroll
DatabaseHealthController | api/health | NO controller policy | GET database; GET financial-manager; GET head-accountant; GET accountant; GET assistant-finance-manager; GET no-mock-data; GET cash-outflow; GET approval-workflow
DeliveryPaymentValidationsController | api/delivery-payment-validations | Authorize (no named policy) | GET (base); GET {id}; POST (base)
DmsIntegrationController | api/integration/dms | AllowAnonymous | GET health; POST waybill-created; POST waybill-intake; POST delivery-completed; POST delivery-failed; POST redelivery-completed; POST delivery-redelivered; POST cash-advance; POST cash-advance-request; POST liquidation; POST liquidation-submission; GET waybills/{waybillNo}
ExecutiveDashboardController | api/financial-manager/executive-dashboard, financial-manager/executive-dashboard | Authorize (no named policy) | GET (base)
ExpensesController | api/expenses, expenses | Authorize (no named policy) | GET transportation; POST transportation
FinancePaymentsController | api | AllowAnonymous marker found | POST speedpay/payments/submit; POST finance/payments/{paymentId}/validate; POST finance/payments/{paymentId}/reject; POST finance/payments/{paymentId}/return; POST finance/payments/{paymentId}/review; GET finance/payments/pending-validation; GET payments/history/{invoiceId}; GET notifications/finance
FinancialManagerController | api/financial-manager, financial-manager | Authorize (no named policy) | GET dashboard; GET clients; GET rate-configurations; GET waybills; POST waybills; GET invoices/eligible-clients; POST invoices/create; GET invoices; GET billing-validation; GET invoice-review; GET accounts-receivable; GET payments; GET official-receipts; GET settlements/pending; GET settlements; POST settlements; GET adjustments; POST adjustments/{id}/approve; POST adjustments/{id}/reject; GET liquidations; GET cash-flow; GET ai/unique-documents; GET ai/review-history; POST reports/generate; GET audit-logs; GET ai/output-history; GET escalated-approvals; GET escalated-approvals/{id}; POST escalated-approvals/{id}/approve; POST escalated-approvals/{id}/reject; POST escalated-approvals/{id}/return
HeadAccountantController | api/head-accountant, head-accountant | Authorize (no named policy) | GET dashboard; GET invoices; GET billing-validation; POST billing-validation/{id}/approve; POST billing-validation/{id}/reject; POST billing-validation/{id}/return; GET invoice-review; POST invoice-review/{invoiceId}/approve; POST invoice-review/{invoiceId}/reject; POST invoice-review/{invoiceId}/return; GET accounts-receivable; GET payment-validation; POST payments/{paymentId}/validate; POST payments/{paymentId}/reject; POST payments/{paymentId}/return; GET speedpay-validation; GET settlements; GET record-settlement; POST settlements/{settlementId}/validate; POST settlements/{settlementId}/reject; POST settlements/{settlementId}/return; POST record-settlement; GET adjustment-validation; POST adjustments/{adjustmentId}/validate; POST adjustments/{adjustmentId}/reject; POST adjustments/{adjustmentId}/return; GET ai/unique-documents; GET for-review; POST for-review/{reviewId}/approve; POST for-review/{reviewId}/reject; POST for-review/{reviewId}/dismiss-flag; POST for-review/{reviewId}/escalate; POST for-review/{reviewId}/mark-resolved; GET review-history; POST reports/generate; GET audit-logs; GET ai/output-history
IntegrationController | (no class route prefix) | AllowAnonymous | POST api/integration/stars/invoice-endorsed; POST api/integration/stars/trigger-endorsement/{invoiceNo}; POST api/integration/stars/trigger-status-sync/{invoiceNo}; POST api/integration/stars/trigger-overdue-alert/{invoiceNo}; GET api/integration/stars/links/{invoiceNo}; POST api/integration/stars/collection-task; POST api/integration/stars/collection-task/{taskId}/execute; GET api/integration/stars/collection-tasks; GET api/integration/stars/routing-metrics; GET api/integration/stars/ar-summary; GET api/integration/stars/accounts-receivable; POST api/integration/stars/provision-user; GET api/integration/stars/check-user-exists; POST api/integration/stars/sync-password
InvoicesController | api/invoices, api/v1/invoices, invoices, billing-invoices, api/billing-invoices | AllowAnonymous marker found | GET lookup/{invoiceNo}; GET (base); GET {id}; POST (base); PUT {id}; POST {id}/{actionName}; DELETE {id}; PUT {id}/archive
LiquidationsController | api/liquidations, api/v1/liquidations, liquidations | AllowAnonymous marker found | GET (base); GET {id}; POST (base); PUT {id}; POST {id}/{actionName}; DELETE {id}
LogsController | api/logs, logs | NO controller policy | GET (base); POST (base)
NotificationsController | api/notifications, api/v1/notifications | Authorize (no named policy) | GET (base); PUT {id}/read
OfficialReceiptsController | api/official-receipts, official-receipts | Authorize (no named policy) | GET (base); GET {id}; POST (base)
PaymentCollectionsController | api/payment-collections | Authorize (no named policy) | GET (base); GET {id}; POST (base)
PaymentConcernTicketsController | api/payment-concern-tickets | Authorize (no named policy) | GET (base); GET {id}; POST (base)
PaymentsController | payments, api/payments, api/v1/payments | Authorize (no named policy) | GET (base); GET {id}; POST (base); PUT {id}; POST {id}/{actionName}; DELETE {id}
PaymongoWebhookController | api/webhooks/paymongo | AllowAnonymous | POST (base)
PayrollController | api/payroll-records | Authorize (no named policy) | GET (base); POST (base)
PayslipsController | api/payslips | Authorize (no named policy) | GET (base); POST (base)
ReceiptsController | api/receipts, api/v1/receipts | Authorize (no named policy) | GET (base); GET {id}; GET checkout/{checkoutId}
ReceivablesController | receivables, ar, api/receivables, api/v1/receivables, api/ar | Authorize (no named policy) | GET records; GET aging; GET follow-ups; POST follow-ups; GET (base); GET outstanding; GET summary; GET aging-accounts; GET overdue-accounts; GET {clientId}; POST (base)
ReportsController | api/reports, api/v1/reports, reports | Authorize (no named policy) | GET (base); POST (base); GET accounts-receivable; GET collection-summary; GET aging; GET financial-statements; GET general-ledger; GET trial-balance; GET payroll; GET reconciliation; GET export/pdf; GET export/excel
RolesController | api/roles | Authorize (no named policy) | GET (base); POST (base)
SearchController | api/search, api/v1/search | Authorize (no named policy) | POST query
SettlementsController | api/settlements, api/v1/settlements, settlements | Authorize (no named policy) | GET (base); GET {id}; POST (base); PUT {id}; POST {id}/{action}
ShipmentPricingController | api/shipment-pricing, api/v1/shipment-pricing | Authorize (no named policy) | GET (base); POST (base); GET rates; GET {id}; POST compute
ShipmentRecordsController | api/shipment-records, api/v1/shipment-records, shipment-records, api/waybills, api/v1/waybills, waybills | AllowAnonymous | GET (base); GET {id}; POST (base); PUT {id}; POST {id}/{actionName}
SpeedPayController | api/[controller], api/v1/[controller] | AllowAnonymous | POST initiate; GET clients; GET invoices; POST seed-client-invoices; GET transactions; POST initiate-invoice; POST webhook; POST simulate-webhook
SpeedPaySharedController | api/speedpay, speedpay | AllowAnonymous | GET payments/pending-validation; POST payments/{paymentId}/validate; POST payments/{paymentId}/reject; POST payments/{paymentId}/return; POST create-payment; POST initiate-payment
SpeedPaySubmissionsController | api/speedpay/submissions, api/v1/speedpay/submissions, speedpay/submissions | NO controller policy | POST validate-proof; POST /api/speedpay/validate-proof; POST (base); GET (base); GET {id}; PUT {id}/status; PUT {id}; POST {id}/verify; POST {id}/{actionName}; GET /api/speedpay/notifications; PUT /api/speedpay/notifications/{id}/read; PUT /api/speedpay/notifications/mark-all-read
SpeedPayTransactionsController | api/speedpay-transactions | Authorize (no named policy) | GET (base); GET {id}; POST (base)
StatementOfAccountsController | api/statement-of-accounts | Authorize (no named policy) | GET (base); GET {id}; POST (base)
TestDataController | api/test-data | Authorize (no named policy) | POST generate
TicketsController | api/tickets, tickets | NO controller policy | GET (base); POST (base); PUT {id}/status
UsersController | api/users, api/v1/users, users | Authorize (no named policy) | GET (base); GET {id}; POST (base); PUT {id}; DELETE {id}
ValidationsController | api/validations, validations | NO controller policy | GET (base); POST (base); PUT {id}/verify
```

Additional endpoint verdicts complete the controller inventory above:

- **KEEP — generic `[Authorize]` present; the role-code gap remains in §d:** `AccountingController`, `ActivityLogsController`, `AdjustmentsController`, `AnalyticsController`, `AuditLogsController`, `BankAdviceController`, `BillingRatesController`, `BillingRecordsController`, `DashboardController`, `ExpensesController`, `NotificationsController`, `PaymentCollectionsController`, `PaymentConcernTicketsController`, `ReceiptsController`, `RolesController`, `SearchController`, `ShipmentPricingController`, `StatementOfAccountsController`, and `UsersController` (rules §§4/9/10/11 as applicable).
- **REWORK — missing controller policy, anonymous business actions, or controller-level authentication is insufficient for the required permission:** `AuditLogsTestController`, `AuthController` (public login/SSO are expected; other actions need explicit review), `DatabaseHealthController`, `DeliveryPaymentValidationsController` (FinanceManager-only per §§5/10), `ShipmentRecordsController` (§10). `AiOutputsController`, `ApprovalsController`, `FinancePaymentsController`, `InvoicesController`, and `LiquidationsController` are already marked REWORK in the table above because of missing or anonymous action-level authorization evidence.
- **REMOVE — explicitly out of scope under §1:** `PayrollController`, `PayslipsController`, `PaymongoWebhookController`, `SpeedPayController`, `SpeedPaySharedController`, `SpeedPaySubmissionsController`, `SpeedPayTransactionsController`, and `TestDataController` (test-data generation is not a production finance endpoint).

---

## c. Database

### Money Columns

| Table | Column | DB Type | C# Type | Verdict | Reason |
|-------|--------|---------|---------|---------|--------|
| Invoices | TotalAmount | decimal(18,2) | decimal | KEEP | Correct per §4 |
| Invoices | FreightCharges | decimal(18,2) | decimal | KEEP | Correct |
| Invoices | Balance | decimal(18,2) | decimal | KEEP | Correct |
| Invoices | AmountPaid | decimal(18,2) | decimal | KEEP | Correct |
| Invoices | VatRate | decimal(18,2) | decimal | KEEP | Live database column is decimal(18,2), compliant with §4 |
| Payments | Amount | decimal(18,2) | decimal | KEEP | Correct |
| CashAdvances | Amount | decimal(18,2) | decimal | KEEP | Correct |
| Liquidations | TotalAmount | decimal(18,2) | decimal | KEEP | Correct |
| CashInflows | Amount | decimal(18,2) | decimal | KEEP | Correct |
| CashOutflows | Amount | decimal(18,2) | decimal | KEEP | Correct |
| ClientRates | MinRate, ExcessRate | decimal(18,2) | decimal | KEEP | Correct |
| AccountsReceivable | OutstandingBalance | decimal(18,2) | decimal | KEEP | Correct |
| ReceivableBalances | BalanceAmount | decimal(18,2) | decimal | KEEP | Correct |

**Floating-point money scan:** No `float` or `real` columns exist in the live SQL Server database snapshot; no money column of type `float`, `real`, or `double` was found in the schema. `Invoices.VatRate` is decimal(18,2) in the live database. This does not resolve source-code or older-migration history; see legacy check #8.

### Statuses Found vs Rules

| Entity / column | Values observed in live database | Allowed by FOMS_RULES.md §2 | Verdict |
|-----------------|---------------------------------|-----------------------------|---------|
| Waybills.delivery_status | Delivered (36) | Delivery state is not a POD status; POD uses Pending, Validated, CTC, OnHold, Rejected | REWORK — separate delivery state from POD status per §2 |
| Waybills.pod_status | Validated (36) | Pending, Validated, CTC, OnHold, Rejected | KEEP — observed value is allowed; live rows do not exercise all states |
| Waybills.legacy_pod_status | Billed (13), Validated (23) | POD allowed values above; billing state should use `is_billed` | REWORK — legacy `Billed` is not a POD status, per §2/§5 |
| Invoices.DocumentStatus | Draft (4), ForReview (2), Approved (3), Received (2) | Draft, ForReview, Approved, Sent, Received, Disputed, Void | REWORK — state set is incomplete in data and stored-state mapping requires audit per §2 |
| Invoices.PaymentValidationStatus | NULL (3), Approved (3), Needs Revision (1), Pending Approval (2), Validated (2) | Invoice document statuses in §2 | REWORK — legacy review values do not match document status values |
| Invoices.PaymentStatus | Unpaid (11) | Unpaid, Paid | KEEP — observed values allowed; Paid path still must satisfy §5 |
| Invoices.invoice_status / validation_status | NULL and Pending Validation / Validated / Approved | Document status in §2 | REWORK — multiple overlapping status columns need one canonical document status |
| Invoices.AgingBucket / DaysOverdue | Columns exist | Aging is derived; never stored, §2/§3 | REWORK — persisted aging fields are prohibited even though no bucket values were observed |
| Payments.payment_status / PaymentStatus | PendingValidation (4), Validated (2) | PendingValidation, Validated, Rejected, OnHold, Exception | KEEP — observed values allowed; record contains parallel status columns needing mapping |
| CashAdvances.Status | Approved (1), Disbursed (2), Pending Finance Review (1) | Requested, Approved, Released, Liquidated, Rejected, Cancelled | REWORK — observed values do not match the defined lifecycle; `Disbursed` is not `Released` |
| Liquidations.Status | Pending Validation (2), Returned (1), Validated (1) | Pending, Validated, Rejected, ForCorrection | REWORK — legacy states differ from §2 |
| AgingAccounts.Status | Current (1), Overdue (2) | Aging is derived and is not a stored status, §2/§3 | REWORK — stored Overdue state is prohibited |
| Settlements.status | For validation (2), Rejected (1), Validated (1) | Payment lifecycle in §2/§5 | REWORK — settlement status must map to the payment validation lifecycle |
| Roles | Financial Manager, Head Accountant, Accountant, Assistant Financial Manager, Billing & Collection Coordinator, Client | FinanceManager, HeadAccountant, Accountant, AssistantFM | REWORK — names and extra roles differ from §§1/10 |

| Other status column | Values observed | Relevant rule | Verdict |
|---------------------|----------------|---------------|---------|
| AccountsReceivable.ar_status | Outstanding (2), Unpaid (1) | Receivable lifecycle under §§5/7 | KEEP — map to the required receivable states |
| AccountsReceivable.refund_status | None (1), Not Required (2) | No refund feature under §1/§5 | REWORK — remove refund-specific state when owner approves removal |
| AIOutputHistory.processing_status | DUPLICATE_FLAGGED, EXTRACTED_HIGH_CONFIDENCE, FLAGGED_HIGH, LOW_RISK, VERIFIED_UNIQUE | AI workflow under §13 | KEEP — AI-specific processing states are not financial statuses |
| BillingDocuments.validation_status | Pending Review (6) | POD/payment status separation under §2/§5 | REWORK — normalize to the specified validation lifecycle |
| BillingDocuments.ctc_status | Hold, Standard, Verified | POD/POD-CTC states under §2/§5 | REWORK — use the specified POD statuses and CTC approval evidence |
| CashInflows.status | Validated (3) | Cash records under §10/§11 | KEEP — observed records are validated inflows |
| CashOutflows.status | Completed (1) | Release-time cash outflow under §10 | REWORK — confirm this reflects the required release/posting event |
| ClientFinanceSettings.finance_status | Active (2) | Client settings under §§4/12 | KEEP — active state is consistent with client configuration |
| Employees.Status | Active (5) | Staff identity/role under §10 | KEEP — observed value is valid; CHECK allows Active, Pending, Locked, Inactive |
| PaymentAdjustments.Status | Pending (1), Approved (1) | Adjustment approval under §5/§8 | REWORK — verify FinanceManager approval and credit-only treatment |
| Reports.status | Generated (6) | Reports under §12; exports audited under §9 | KEEP — generated report state is expected |
| ShipmentRecords.Status | Completed (4), For Checking (10), Validated (3) | POD and waybill states under §2/§5 | REWORK — align delivery/POD statuses and keep them separate |
| StarsCollectionTasks.status | Assigned (1), Completed (2) | STARS collection task integration under §11 | KEEP — task states do not pay an invoice |
| StatusMigrationReports.match_status | MATCH (1) | MIG-02 evidence retention under §9 | REWORK — preserve report until migration disposition is approved |
| WaybillDuplicateAlerts.status | No stored rows; default Pending Review | Duplicate review under §5 | KEEP — review state is appropriate; no alert rows are currently present |

Stored values above are the values present in rows at the snapshot time, not an exhaustive declaration of application-accepted values. Most status columns are unconstrained `nvarchar`; only 9 database CHECK constraints exist in total, so the database does not centrally enforce all §2 status sets.

### Constraints and Indexes

| Metadata | Live count | Verdict | Reason |
|----------|------------|---------|--------|
| Primary-key constraints | 82 | KEEP | Tables have primary-key coverage; required for reliable financial records under §§7-11 |
| Foreign-key constraints | 22 | REWORK | Review referential coverage against business relations in §§5-11; count alone does not establish complete integrity |
| Unique constraints | 10 | REWORK | Verify coverage for invoice sequence, waybill uniqueness and payment references under §5/§8 |
| CHECK constraints | 9 | REWORK | Status/amount rules in §§2/4/5/8 are not comprehensively enforced at the database layer |
| DEFAULT constraints | 181 | KEEP | Defaults support existing records; review each when statuses are normalized under §2 |
| Indexes (all) | 340 | REWORK | Inventory exists; validate list-query and uniqueness coverage against §10/ENGINEERING.md paging requirements |
| Unique indexes (included in total above) | 269 | REWORK | Verify business-key uniqueness and avoid treating unrelated unique indexes as duplicate guards under §5/§8 |

### Triggers

| Trigger | Table | Purpose | Verdict |
|---------|-------|---------|---------|
| TR_AuditLogs_PreventDelete | AuditLogs | Prevents DELETE — append-only | KEEP — matches §9 audit-log immutability requirement |
| TR_AuditLogs_PreventUpdate | AuditLogs | Prevents UPDATE — append-only | KEEP — matches §9 |
| trg_Clients_AssignClientId | Clients | Auto-assigns ClientId on INSERT | KEEP — supports client identifiers under §4 |

### Complete Table Inventory (82 tables; live snapshot)

| Table | Rows | Verdict | Reason |
|-------|------|---------|--------|
| __EFMigrationsHistory | 15 | KEEP | Tracks schema history for MIG-01/MIG-02 |
| AccountsReceivable | 3 | KEEP | Required receivables under §5/§7 |
| ActivityLogs | 0 | REWORK | Map to the authoritative append-only audit log required by §9 |
| AgingAccounts | 3 | REWORK | Aging must be derived, not stored, under §2/§3 |
| AIOutputHistory | 5 | KEEP | AI history is in scope under §13 |
| AIReviewHistory | 2 | KEEP | AI review records are in scope under §13 |
| AppAuditLogs | 121 | REWORK | Reconcile duplicate audit stores and enforce §9 append-only retention |
| ApprovalThresholdSettings | 1 | KEEP | Approval thresholds are governed by §1/§6 |
| Archive_AuditLogs | 0 | REWORK | Confirm archive process preserves §9 retention and immutability |
| AuditLogs | 64 | KEEP | Required append-only audit evidence under §9 |
| BankAdviceRecords | 0 | KEEP | Supports payment evidence and validation under §5/§8 |
| BankBalances | 0 | KEEP | Supports bank reconciliation under §8/§11 |
| BillingDocuments | 6 | KEEP | Supports POD/billing review under §5/§6 |
| CashAdvances | 4 | KEEP | Required cash-advance lifecycle under §10 |
| CashFlowTransactions | 15 | REWORK | Reconcile with validated inflow/outflow ledger postings under §§10/11 |
| CashInflows | 3 | KEEP | Required cash inflows under §10 |
| CashOutflowApprovalHistory | 0 | KEEP | Approval history is required audit evidence under §§6/9 |
| CashOutflowApprovalRequests | 0 | KEEP | Outflow approval workflow is required under §6 |
| CashOutflows | 1 | KEEP | Required cash outflows under §10 |
| ChartOfAccounts | 0 | KEEP | Required chart of accounts under §11 |
| ClientFinanceSettings | 2 | KEEP | Client terms/settings support §§3/4 |
| ClientRates | 30 | KEEP | Client-effective rates are required under §4 |
| Clients | 7 | KEEP | Required client records under §4 |
| CreditMemos | 0 | KEEP | Credit memo reduces receivables, not cash, under §5 |
| DeliveryPaymentValidations | 0 | REWORK | Ensure validation is FinanceManager-only under §5/§10 |
| Departments | 6 | KEEP | Shared departments are required under §6 |
| Employees | 5 | KEEP | Staff identities/roles are required under §10 |
| ExceptionRecords | 0 | KEEP | Payment exceptions are required under §2/§5 |
| ExecutiveApprovalRecords | 3 | KEEP | CEO approvals recorded by FinanceManager are required under §1 |
| FinanceManagerDelegates | 1 | KEEP | Delegation is required and actions must be flagged under §1 |
| FinancialAdjustments | 0 | KEEP | Adjustments are in scope under §5/§8 |
| GeneralLedgerEntries | 0 | KEEP | Ledger entries are required under §11 |
| InvoiceComputations | 1 | KEEP | Billing computations must be traceable under §4 |
| InvoiceLineItems | 1 | KEEP | Invoice lines support the §4 computation model |
| Invoices | 11 | KEEP | Required invoice lifecycle under §§2/5/6 |
| JournalEntries | 0 | KEEP | Balanced postings are required under §11 |
| LegacyStatusMigrationReviews | 42 | REWORK | Preserve migration decisions until owner approves retention under §9/MIG-02 |
| LiquidationDocuments | 0 | KEEP | Liquidation proofs are required under §10 |
| LiquidationLineItems | 0 | KEEP | Liquidation expense detail supports §10 |
| Liquidations | 4 | KEEP | Required liquidation lifecycle under §2/§10 |
| MigrationReviewItems | 0 | REWORK | Confirm MIG-02 evidence retention before any cleanup under §9 |
| Notifications | 0 | KEEP | Supports logged follow-up/notification workflows under §§5/9 |
| OfficialReceipts | 0 | REWORK | Store collector OR reference only; FOMS must not generate a separate OR under §5 |
| OfficialReceiptSequences | 0 | REWORK | A generated-document sequence conflicts with §5 OR-reference rule |
| PaymentAdjustments | 2 | KEEP | Payment adjustments are governed by §5/§8 |
| PaymentCollections | 0 | REWORK | Reconcile collection records with validated full payments under §5 |
| PaymentConcernTickets | 0 | REWORK | Map payment concerns to ExceptionRecord lifecycle under §2/§5 |
| PaymentHistories | 0 | REWORK | Reconcile duplicate history stores with append-only audit under §9 |
| PaymentHistory | 0 | REWORK | Reconcile duplicate history stores with append-only audit under §9 |
| PaymentReceipts | 0 | REWORK | Must represent required proof/reference, not a generated OR, under §5 |
| Payments | 6 | KEEP | Required full-payment validation under §5/§8 |
| PaymentTransactions | 0 | REWORK | Ensure records do not represent a prohibited payment gateway under §1/§5 |
| PaymentValidations | 0 | KEEP | Supports FinanceManager payment validation under §5 |
| PayrollDeductionLines | 0 | REMOVE | Payroll is explicitly out of scope under §1 |
| PayrollRecords | 0 | REMOVE | Payroll is explicitly out of scope under §1 |
| Payslips | 0 | REMOVE | Payroll is explicitly out of scope under §1 |
| ProcessedWebhookEvents | 0 | REWORK | Keep only for allowed idempotent integrations; no gateway may pay invoices under §1/§11 |
| ReceivableBalances | 3 | KEEP | Supports receivable balances under §5/§7 |
| RefreshTokens | 144 | KEEP | Supports staff authentication/session security under §1/§10 |
| RefundRequests | 0 | REMOVE | Refund feature is explicitly prohibited under §1/§5 |
| Reports | 6 | KEEP | Required financial/reporting area under §12 |
| RevokedTokens | 5 | KEEP | Supports staff session/token security under §10 |
| Roles | 6 | REWORK | Reconcile names and remove non-FOMS roles under §§1/10 |
| Settlements | 4 | KEEP | Payment/settlement workflow is in scope under §5/§8 |
| ShipmentPricings | 0 | REWORK | Reconcile with client effective-dated rate source under §4 |
| ShipmentRates | 0 | REWORK | Reconcile with ClientRates effective-dated rate source under §4 |
| ShipmentRecords | 17 | KEEP | Shipment/waybill delivery evidence is required under §5 |
| SpeedPayManualSubmissions | 3 | REMOVE | SpeedPay/client payments are explicitly prohibited under §1 |
| SpeedPayTransactions | 0 | REMOVE | Payment gateway transactions are explicitly prohibited under §1 |
| StarsCollectionTasks | 3 | KEEP | STARS collection task integration is in scope under §§5/11 |
| StarsInvoiceEndorsementLinks | 0 | KEEP | Approved invoice endorsement to STARS is required under §5/§11 |
| StatementOfAccounts | 0 | KEEP | Financial statements are required under §11 |
| StatusMigrationReports | 1 | REWORK | Preserve migration evidence until MIG-02 disposition approved under §9 |
| SupportTickets | 0 | REWORK | Confirm this staff-only support function is in scope under §1 |
| sysdiagrams | 0 | REWORK | SQL Server diagram metadata is not a FOMS business table; DBA disposition required |
| TransportationExpenses | 0 | REWORK | Map to approved category/department expense posting under §§6/11 |
| TrialBalances | 0 | KEEP | Period statements require trial balance under §11 |
| UserActivityLogs | 0 | REWORK | Reconcile with authoritative append-only audit requirements under §9 |
| UserClientMappings | 2 | REWORK | Client login is prohibited; verify mappings are not access grants under §1 |
| Users | 8 | KEEP | FOMS staff identities are required under §§1/10 |
| WaybillDuplicateAlerts | 0 | KEEP | Duplicate waybill alerts are required under §5 |
| Waybills | 36 | KEEP | Waybill/POD billing source is required under §5 |

---

## d. Roles and Permissions

### Roles Found vs Required

| Role Name (DB) | Required by §1/§10 | Verdict |
|----------------|-------------------|---------|
| Financial Manager | Yes (`FinanceManager` in spec) | REWORK — database display role differs from exact `FinanceManager` identifier in §1 |
| Head Accountant | Yes (`HeadAccountant` in spec) | REWORK — database display role differs from exact `HeadAccountant` identifier in §1 |
| Accountant | Yes | KEEP |
| Assistant Financial Manager | Yes (`AssistantFM` in spec) | REWORK — database display role differs from exact `AssistantFM` identifier in §1 |
| Billing & Collection Coordinator | No — STARS role, not a FOMS role | REMOVE — STARS owns login; this role should not be a FOMS login role under §1/§11 |
| Client | No — §1 explicitly excludes client login | REMOVE — client login is prohibited under §1 |

### Permission Matrix Gaps

| Gap | Evidence | Verdict |
|-----|----------|---------|
| Required permission codes vs API enforcement | `Program.cs` calls generic `AddAuthorization()`; no policy-code definitions for the §10 codes were found in the baseline | REWORK — implement/verify API policies for every matrix code under §10 |
| Accountant scope | UI modules assign client management, invoice creation, AR, payment recording and limited reports | REWORK — verify every action maps to the Accountant codes in §10; UI role maps are not API authorization |
| HeadAccountant scope | UI modules assign invoice review, payment review, adjustment review and account audit | REWORK — verify exact §10 codes and ensure it cannot validate payments under §5 |
| AssistantFM scope | UI modules assign approvals, liquidations, cash advances and duplicate review | REWORK — verify exact §10 codes and no FinanceManager-only actions |
| FinanceManager scope | UI modules assign escalated approvals, cash flow and management views | REWORK — verify all FinanceManager-only codes and delegate audit flag under §§1/10 |
| Payment validation assignment | `HeadAccountantController.ValidatePayment` exists in the baseline; payment validation UI is assigned to HeadAccountant | REWORK — only FinanceManager/delegate may validate payment under §5 |
| Anonymous/action authorization | Controller inventory below identifies `[AllowAnonymous]` or missing role/policy checks; generic `[Authorize]` is not a §10 policy code | REWORK — enforce server-side authorization by policy code under §10 |

---

## e. Integrations

| Integration | Implementation | Status | Verdict |
|-------------|---------------|--------|---------|
| STARS | `StarsIntegrationService.cs`, `StarsIntegrationController.cs`, `StarsCollectionTasks` table | Active — API-key authenticated outbound; inbound webhook at `/api/integration` lacks auth | REWORK — inbound integration endpoint needs API-key guard |
| DMS | `DmsIntegrationService.cs`, `DmsIntegrationController.cs` | Active — `[AllowAnonymous]` on controller; auto-creates invoices on delivery complete | REWORK — needs API-key auth; auto-invoice on delivery is legacy check #4 |
| PayMongo / SpeedPay | `PaymongoWebhookController.cs`, `SpeedPayController.cs`, `SpeedPaySharedController.cs`, `SpeedPaySubmissionsController.cs`, `speedpay-portal/` directory | Present — webhook at `/api/paymongo-webhook`, portal at port 5174 | REMOVE — explicitly out of scope per §1 |

---

## f. Legacy Flow Checks

### (1) Partial payments or Partially Paid status
**FOUND**  
`foms-backend/FOMS.Application/Features/SpeedPayFeatures.cs:218` — comment states "if request.Amount < invoice.Balance, partial is accepted."  
`SpeedPaySharedController.cs:96` — `invoice.OutstandingBalance = Math.Max(0, invoice.TotalAmount - (invoice.PaidAmount ?? 0))` logic implies partial.  
Contradicted by SpeedPay.tsx UI text "Full payment only. Partial payments are not accepted" but backend code path allows it.  
Per §8: payment status is binary (Unpaid/Paid). No partial tracking allowed.

### (2) Anyone other than the Finance Manager validating payments
**FOUND**  
`HeadAccountantController.cs:347` — `[HttpPost("validate-payment")]` method `ValidatePayment`.  
`SpeedPaySharedController.cs:81` — `ValidatePayment` callable without role restriction.  
Per §8: only the FinanceManager may validate payments.

### (3) Any integration, webhook or gateway setting an invoice to Paid
**NOT FOUND**  
`PaymongoWebhookController.cs` — `ProcessSpeedPayWebhookCommand` sets `PaymentStatus = "Pending Payment Validation"` only; never sets "Paid" directly. ✓

### (4) Invoice created directly when a delivery completes
**FOUND**  
`DmsIntegrationService.cs:ProcessDeliveryCompletedAsync` — after upserting the waybill and POD, the method immediately computes billing charges and creates an `AppInvoice` with `InvoiceNo = "INV-DMS-{waybillNo}"` without human review.  
Per §5/§6: waybill must be validated/CTC first, then invoiced by an Accountant. Auto-creation on delivery bypasses this workflow.

### (5) Document status and payment status in one field
**NOT FOUND** (but status names diverge)  
Two separate fields exist: `Invoice.PaymentValidationStatus` (document lifecycle) and `Invoice.PaymentStatus` (payment state). The fields are separate. However, their allowed values diverge from spec — see §c statuses. Not a single-field conflation.

### (6) Overdue or aging stored as a status
**FOUND**  
`AgingAccounts.Status` has stored `Current` and `Overdue` values; the `Invoices` table also has `AgingBucket` and `DaysOverdue` columns. The invoice `PaymentStatus` rows in the live snapshot are currently `Unpaid`; the violation is the persisted aging status/fields.  
Per §2/§3: Overdue and aging buckets must be derived, never stored.

### (7) Approved invoices editable
**FOUND**  
`InvoicesController.cs:UpdateInvoice` — the method fetches the invoice and updates `TotalAmount`, `FreightCharges`, `Description`, `DueDate` and `WaybillIds` with **no guard on the current status**. An invoice with `PaymentValidationStatus = "Approved"` can be edited freely.  
Per §6: "No edit after Approved. Corrections use a credit memo."

### (8) Float money or typed-in rates or a bare total
**FOUND**  
The live database scan found no `float` or `real` columns and `Invoices.VatRate` is `decimal(18,2)`. However, `DmsIntegrationService.cs` hardcodes a base-rate calculation (`decimal baseRate = 150.00m`) instead of reading the client's effective signed rate row.  
Per §4: money uses decimal and all rates come from the client's effective-dated rate table; the typed-in-rate finding is **FOUND**.

### (9) Credit memos or discounts treated as cash outflow
**NOT FOUND**  
`AdjustmentFeatures.cs` — adjustments reduce `invoice.Balance` only; no `CashOutflow` row is created. ✓

### (10) Outflow posted at liquidation instead of release
**FOUND**  
`LiquidationsController.cs:247` — when a liquidation is validated, a `CashOutflow` row is added for `ReimbursementAmount`. The outflow for the original cash advance should have been posted at **release** (CashAdvance status → Released), not at liquidation validation.  
Per §10: cash outflow is recorded at release time.

### (11) Official Receipt as a separate generated document
**FOUND**  
`OfficialReceiptsController.cs` exists with CRUD endpoints.  
`OfficialReceipts` and `OfficialReceiptSequences` tables exist in the DB.  
Per §8: FOMS records that a payment was received; it does not generate OR documents. The OR tracking table may be kept for record-keeping, but generation/printing endpoints must be removed.

### (12) Receivable created at the wrong time or due date not from received date
**FOUND**  
`DmsIntegrationService.cs:181` — sets `DueDate = now.AddDays(30)` (creation date + 30, not received date + 30).  
`InvoicesController.cs:319` — sets `DueDate = submission.DueDate ?? DateTime.UtcNow.AddDays(30)` using current time, not `receivedDate`.  
`StarsIntegrationService.cs:264` — `newDueDate = actualReceived.AddDays(30)` ✓ — this one is correct per §3.  
`BillingComputationService.cs:RecalculateInvoice` reads `invoice.DueDate` as already set.  
Per §3: `dueDate = receivedDate + creditTermDays`. All paths except STARS use the wrong anchor date.

### (13) Missing duplicate alerts or zero and negative guards
**NOT FOUND** (guards are present)  
Zero/negative guards: `CashAdvancesController.cs:141`, `CashOutflowsController.cs:81`, `AdjustmentFeatures.cs:134`, `PaymentFeatures.cs:69`, `CashFlowFeatures.cs:78`, `ExpenseFeatures.cs:51` all have `Amount <= 0` checks.  
Duplicate detection: `AiDuplicatesController`, `AccountantController.cs` AI duplicate scan, `PaymentFeatures.cs:72` duplicate OR number guard, `SpeedPaySubmissionsController.cs:131` duplicate payment check all present.  
Guards are in place. ✓

### (14) Role gaps, clients or non-finance roles seeing amounts, editable audit log
**FOUND**  
- `Client` role exists in the DB (see §d) — a non-finance role that should not exist.
- `Billing & Collection Coordinator` role exists — STARS role in FOMS DB.
- `ClientsController` is `[AllowAnonymous]` — any unauthenticated request can read client credit terms and amounts.
- `LogsController` is `[AllowAnonymous]` — audit logs readable without authentication.
- `TR_AuditLogs_PreventDelete` / `TR_AuditLogs_PreventUpdate` triggers exist — audit log is append-only ✓, but unauthenticated read access remains a gap.

### (15) Any SpeedPay, client portal or PayMongo code, pages, routes, tables or settings
**FOUND**  
- `speedpay-portal/` directory — full client portal (separate Vite app, port 5174)  
- `foms-frontend/src/pages/SpeedPay.tsx` — SpeedPay payment page  
- `foms-frontend/src/utils/roleAccess.ts:PUBLIC_PATHS` includes `/speedpay`  
- `PaymongoWebhookController.cs` — PayMongo webhook handler  
- `SpeedPayController.cs`, `SpeedPaySharedController.cs`, `SpeedPaySubmissionsController.cs` — 3 backend controllers  
- `SpeedPayTransactions` table (0 rows), `SpeedPayManualSubmissions` table (3 rows)  
- `.env.example` — `PAYMONGO_PUBLIC_KEY`, `PAYMONGO_SECRET_KEY`, `VITE_PAYMONGO_PUBLIC_KEY`  
- `SpeedPayFeatures.cs` — `foms-backend/FOMS.Application/Features/`  
All must be REMOVED per §1.

### (16) UI that breaks the Design System
**FOUND**  
- `linear-gradient` CSS in ~10 page files (Dashboard.tsx, SpeedPay.tsx, BillingValidation.tsx, StarsCollection.tsx, etc.) — spec §9 requires solid color tokens only.  
- `LoadingSpinner` component used in 7+ pages — spec §9 requires skeleton loaders for content loading.  
- Solid-filled status badge styles conflict with the Engineering Conventions design-system rule requiring non-solid badges.  
- Tailwind is **NOT FOUND**: no Tailwind dependency, configuration, or `@tailwind` directive; the project uses custom CSS class names and has no Tailwind framework usage.  
- `axios` in `foms-frontend/package.json` — spec §9 prohibits third-party HTTP clients; use `fetch`.  
- Icon-only buttons without accessible text or tooltip and developer/test wording in fallback labels are present in baseline UI/controller paths.  
- Frontend lint: 5 pre-existing ESLint errors in `employeeValidation.test.tsx` and `ProfilePage.tsx`.  
- Frontend tests: 22 pre-existing failures in `duplicateDetection.test.tsx`, `fmCrudSync.test.tsx`, `dashboardAndSidebar.test.tsx`, `postLoginRedirect.test.tsx`.

### (17) Closed periods editable or statements not reconciling
**NOT FOUND** (feature not yet implemented)  
No `AccountingPeriod` entity, controller, or table found in backend or DB. The `FinancialPeriod` / `AccountingPeriod` with `Open`/`Closed` status required by §2 does not exist. Period-close is a Phase 11 deliverable; no code to audit yet. Statements reconciliation (TrialBalances, StatementOfAccounts tables exist with 0 rows) also not implemented.

### (18) Any refund request, refund approval, refund release or refund cash outflow code, pages or tables
**FOUND**  
`RefundRequests` table exists in the DB (0 rows) — schema is defined even though no data exists and no controller was found in the backend.  
Per §1: "NO refund feature." Table must be dropped.

### (19) Reimbursement validated after approval or returned leftover cash not counted as inflow
**NOT FOUND** (for the core FOMS reimbursement workflow)  
`LiquidationsController.cs:ValidateAction` — when a liquidation is validated:  
1. If `LeftoverCash > 0`, a `CashInflow` row is created ✓ (leftover returned cash is counted as inflow).  
2. If `ReimbursementAmount > 0`, a `CashOutflow` row is created (courier reimbursement posted at liquidation validation, which is a check #10 issue but not a check #19 issue).  
The spec §10 reimbursement entity (Submitted → Validated by AFM → Approved by FM → Paid) does not exist as a separate entity; reimbursements are embedded in the `Liquidations` table as a money field. This is a gap but not the specific anti-pattern of "validated after approval."  
The leftover cash → CashInflow path is correctly implemented ✓.

---

## g. Data Assessment

### Row Counts and Table Verdicts

The complete 82-table census, each table's exact count, and its KEEP/REWORK/REMOVE verdict are in §c, sourced from `sys.tables` and `sys.partitions` on 2026-11-05. Counts include empty tables. No data rows were changed.

### Data Verdict: MIXED / TEST-LIKE; TREAT AS POTENTIALLY REAL

**Evidence:**
1. **Test labels:** Database users include `Financial Manager Test User`, `Head Accountant Test User`, `Accountant Test User`, and `Assistant FM Test User`; employee numbers include sequential `EMP-001` through `EMP-007`.
2. **Small volume and narrow date range:** 11 invoices, 7 client rows, 6 payments, and records dated mostly 2026-09 through 2026-11 look like a seeded/demo dataset.
3. **Mixed evidence:** Client names include Lazada, Shopee, TikTok Shop and Zalora; some user names are non-test names; invoice totals include both round amounts and smaller computed amounts. These names and records cannot be proven synthetic from metadata alone.
4. **Technical rows:** `LegacyStatusMigrationReviews` has 42 records and `StatusMigrationReports` has 1, indicating migration/test activity, not proof that all business data is synthetic.

**Conclusion:** The dataset looks substantially test/demo-oriented, but it is mixed/indeterminate. Do not treat it as disposable or safe to overwrite; preserve all rows and obtain owner confirmation before any migration or cleanup.

---

## APPROVAL

OWNER APPROVAL STATUS: PENDING
Approved removals and reworks: (none yet)
