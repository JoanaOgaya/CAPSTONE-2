# FOMS RULES (source of truth: FOMS Merged Requirements Revision 3)

## 1. Scope
- FOMS = Speedex Finance Operations Management System. Users are Speedex staff only.
- Roles (exact names in code): FinanceManager, HeadAccountant, Accountant, AssistantFM (Assistant of Finance Manager).
- NO client login, NO client portal, NO SpeedPay, NO PayMongo, NO payment gateway, NO webhooks that pay invoices, NO refund feature, NO payroll, NO IPO or SEC or external audit module.
- Peers: STARS (central login, invoice endorsement, collection tasks) and DMS (deliveries, PODs, cash advance requests).
- The CEO/president has no login. A CEO approval is recorded by the FinanceManager as a CeoApproval row: approver name, approval date, evidence (file or reference text), linked record type and id. Discounts, budget transfers, carry-overs, the annual budget, large outflows and large overrides need a CeoApproval.
- Delegate: the FinanceManager can configure a delegate user with FinanceManager permissions for a date range. Every action by a delegate is logged with a delegate flag.

## 2. Stored statuses (each record has its own status field)
- Waybill/POD: Pending, Validated, CTC, OnHold, Rejected. Validated = original client-signed POD matched to Accounting's copy. CTC = original lost, certified true copy attached with reason and approver. Both billable; CTC flagged on invoice and audit. OnHold = failed delivery or floating counterpart.
- Invoice document status: Draft, ForReview, Approved, Sent, Received, Disputed, Void. A failed review returns the invoice to Draft with a reason. No edit after Approved. Corrections use a credit memo. Sent creates the receivable. Received sets the due date.
- Invoice payment status: Unpaid, Paid. Paid only when validated payments equal the invoice amount. No partial status.
- Payment: PendingValidation, Validated, Rejected, OnHold (unidentified), Exception (short, over, duplicate).
- ExceptionRecord: Open, Resolved, Rejected. Every exception ends with a reason. A resolved payment goes back to PendingValidation. It never becomes Paid directly.
- Liquidation: Pending, Validated, Rejected, ForCorrection. Late is a FLAG derived from the deadline, not a status.
- CashAdvance: Requested, Approved, Released, Liquidated, Rejected, Cancelled.
- DirectDisbursement: Requested, Approved, Released, Rejected, Cancelled.
- Reimbursement: Submitted, Validated, Approved, Paid, Rejected. Order: AssistantFM validates, then FinanceManager approves (Committed), then Paid (Actual).
- DepartmentBudgetProposal: Draft, Submitted, Approved, Rejected.
- AccountingPeriod: Open, Closed.
- Never store: Overdue, aging bucket, Available, Remaining. They are derived.

## 3. Derived values
- dueDate = receivedDate + creditTermDays (default 30, per client, calendar days).
- daysPastDue = today - dueDate. DueSoonDays default 7 (setting).
- Bucket: NotYetDue if daysPastDue < -DueSoonDays; DueSoon if -DueSoonDays <= daysPastDue <= 0; then 1-30, 31-60, 61-90, 90+ by daysPastDue. An invoice that is Sent but not Received has no due date and no bucket (shown as Awaiting Acknowledgment). Paid and Void invoices have no bucket.
- Budget line: Available = Budget - Committed - Actual. Remaining = unused monthly budget (Budget - Actual), shown only, no automatic carry-over.

## 4. Money and billing computation
- Money is decimal(18,2) PHP. Never float or double. Each computed line is rounded to 2 decimals with MidpointRounding.AwayFromZero. One shared Money helper, used everywhere.
- chargeableKg = max(volumetricKg, actualKg). volumetricKg = (L x W x H in cm x pieces) / 3500.
- freight = Rmin + max(0, chargeableKg - 5) x Rexcess. The 5 kg is a field on the rate row (MinWeightKg, default 5).
- valuation = valuationPct x declaredValue (default 1%).
- oda = the client's flat ODA amount per waybill when the waybill is flagged ODA, else 0.
- subtotal = freight + valuation + oda.
- vat = 0.12 x subtotal.
- fuelSurcharge = fuelRate x freight. The surcharge is added after VAT and is not taxed (follows the sample).
- waybillTotal = subtotal + vat + fuelSurcharge. invoiceTotal = sum of waybill totals, then the discount line (negative) if any.
- Default base rates (used only to seed the test client and for tests; real rates come from each client's signed proposal): NCR min 100 excess 25; Luzon 130 and 45; Visayas 150 and 50; Mindanao 150 and 50.
- Rate rows carry an effectiveFrom date and an approver. Old rows are kept. An invoice uses the row effective on the waybill delivery date and stores the rate it used.
- TEST VECTOR (must pass exactly): 2 boxes, 35x50x25 cm, actual 20 kg, NCR (100, 25), declared 1000, ODA 0, fuel 15%. volumetric 25 kg; freight 600.00; valuation 10.00; subtotal 610.00; VAT 73.20; before fuel 683.20; fuel 90.00; total 773.20.
- Zero/negative guard: any computed line, invoice, balance or payment <= 0 is blocked and sent to an exception queue with a clear reason. The only legitimate negative is an overpayment, held as an unapplied credit.
- A discount (usually 10%, configurable cap, default 10%) needs a CeoApproval and is its own negative line, deducted from the invoice total. It is never a cash outflow.

## 5. Billing, AR and payment rules
- Deliver first, invoice after. Only a Validated or CTC POD is billable. A waybill is billed once and is then locked to its invoice. OnHold or Rejected waybills cannot enter a billing run.
- Duplicate waybill number: alert at entry and on receipt, block billing until reviewed.
- Billing schedules: Monthly (default), Weekly, TwiceMonthly (15/30). Invoice numbers are sequential with no gaps.
- Pre-alert (BIL-06) on a suspect computation: missing rate, deviation from rate configuration, unusual total (a waybill total above 3 times the client's average waybill total, or an invoice above 3 times the client's average invoice, when at least 5 prior invoices exist).
- HeadAccountant reviews and approves invoices and does random-check sampling (default 10% of invoices flagged for a closer look). Approved invoice is immutable. Void needs a reason.
- After Approved, the invoice is released to Operations through the STARS endorsement task. Sent creates the receivable and recognizes accrual revenue. Received (from STARS or recorded by the Accountant) sets the due date.
- Follow-up about 7 days after billing if no acknowledgment, then at due soon and overdue. Every follow-up is logged. A Disputed invoice has a reason code, stays in receivables and is excluded from collection prioritization.
- Payment channels: Check, BankTransfer, Cash. No partial payments. One payment can settle several invoices, each in full. Proof is required (PDF, JPG, PNG). Only the FinanceManager (or delegate) validates after confirming funds entered the bank or cash account.
- Invoice becomes Paid only when validated payments equal the invoice amount. Short, over, duplicate (same bank or collector reference) or unidentified payments go to the exception queue.
- The collector's reference number is the Official Receipt (OR) reference, linked to the payment and invoice. The invoice is the principal tax document.
- Credit memo: lost or damaged cargo, linked to invoice or waybill, reduces the receivable, never a cash outflow. If the invoice is already Paid, the credit becomes a client credit balance applied to the client's next invoice. There is no refund anywhere in FOMS.
- Overpayment: held as an unapplied credit, applied by the FinanceManager to the client's other open invoices.

## 6. Budget and cash rules
- Budget level: category x department x month, rolling up to the annual total. Departments come from one shared list used by DMS and FOMS. No weekly budget. Reports show weekly actuals against the monthly budget.
- Categories: Fuel, Toll, Parking, FoodAllowance, Vulcanizing, Hotel, OfficeSupplies, RepairsAndMaintenance.
- Proposal flow: department estimate (recorded by AssistantFM on behalf of the department) per category per month with historical actuals shown, FinanceManager approves, CEO/president approves the annual budget (CeoApproval), FinanceManager allocates among departments and categories.
- Budget check on every cash advance, direct disbursement and reimbursement: Available = Budget - Committed - Actual for its category, department and month. Over budget is a SOFT block: allowed only with override, reason and approver. FinanceManager approves overrides at or below the CSH-09 threshold, CEO/president (CeoApproval) above it.
- Approval sets Committed. Validated liquidation turns Committed into Actual and releases unused commitment. Rejected or cancelled releases the commitment. Direct disbursement becomes Actual at release. Reimbursement becomes Actual when Paid. No expense is counted twice.
- Transfers (between categories or departments) and carry-overs: FinanceManager requests, CEO/president approves with a reason. Company total unchanged. History kept. No automatic carry-over.
- Alerts to the FinanceManager at a configurable percentage (default 80%) and at 100% of the monthly budget.
- CSH-09 threshold: a setting with NO default value. Null threshold means: every budget override needs a CeoApproval, and the large-outflow check is skipped with a visible warning on the Settings page.
- Cash accounts: Bank and CashOnHand, tracked separately. Net cash = beginning balance + validated inflows - validated outflows. Inflows: validated client payments, returned unused advances. Outflows: cash advance release, direct disbursement release, paid reimbursement, other approved expense records. An outflow above the threshold needs a CeoApproval before posting.
- Cash advance: requested (from DMS or recorded by authorized staff) with category, department, purpose, amount, then budget check, approval (Committed), release (outflow posted), activity, liquidation, validation. Liquidation due next day for NCR/Luzon, on return for out-of-delivery-area trips. Late items are flagged for deduction from the liable person. The deduction happens outside FOMS.
- Liquidation lines: category, amount, date, original receipt attachment. Rejection reasons (dropdown): WrongReceiptDateOrAmount, ManualFuelReceipt, LateSubmission, Other (remarks required). Leftover cash returned is an inflow. Overspend is reimbursed only with a recorded supervisor pre-approval and an original receipt.

## 7. Ledger (balanced entries) and chart of accounts
- Every financial event posts a balanced journal entry (debits = credits) with category and department tags, source type and id, and the accounting period. Closed periods reject postings. A correction is a new correcting entry referencing the original. Originals are never edited or deleted.
- Accounts: 1010 CashOnHand, 1020 CashInBank, 1100 AccountsReceivable, 1200 EmployeeAdvances, 2000 AccountsPayable, 2100 ClientCreditBalance, 2200 VatPayable, 3000 OwnersEquity, 3100 RetainedEarnings, 4000 DeliveryRevenue, 4100 SalesDiscounts (contra), 4200 CreditMemos (contra), 5000 Expenses (one sub-account per category, tagged by department).
- Postings: (a) invoice Sent: Dr 1100 invoice total, Dr 4100 discount if any; Cr 4000 (subtotal + fuel surcharge, summed over waybills), Cr 2200 VAT. (b) payment Validated: Dr 1020 or 1010, Cr 1100. (c) credit memo: Dr 4200, Cr 1100 (or Cr 2100 if the invoice is already Paid). (d) overpayment validated: Dr cash, Cr 2100. Applying credit: Dr 2100, Cr 1100. (e) cash advance Released: Dr 1200, Cr cash. (f) liquidation Validated: Dr 5000 (by category), Cr 1200. Returned leftover: Dr cash, Cr 1200. (g) reimbursement Approved: Dr 5000, Cr 2000. Paid: Dr 2000, Cr cash. (h) direct disbursement Approved: Dr 5000, Cr 2000. Released: Dr 2000, Cr cash. (i) other expense record: Dr 5000, Cr cash (or Cr 2000 if unpaid). (j) opening balances at go-live: Dr assets, Cr liabilities, Cr 3000, entered once, approved by FinanceManager.
- Income statement: accrual basis = revenue at invoice Sent minus discounts and credit memos minus expenses per the ledger. Cash basis = validated collections minus cash outflows net of returned advances. Show profit or loss for both side by side.
- Statement of financial position: assets (1010, 1020, 1100, 1200) = liabilities (2000, 2100, 2200) + equity (3000, 3100, current period profit). Fixed assets and depreciation are stretch and not built.
- Statement of cash flows (direct method): beginning cash + validated inflows - validated outflows = ending cash. Statement of changes in equity: opening equity + profit or loss - withdrawals = closing equity. Notes: revenue per client, expenses per category.
- Comparison: current period vs previous period, previous year, approved budget.
- Annual financial statements (AFS) package: the five parts, exportable to Excel and PDF. CEO/president approval recorded. An attach slot holds the audited AFS file from the external auditor. FOMS never generates the audited AFS.

## 8. Period close (FinanceManager only)
Checklist, all must pass: (a) all payments validated, (b) all liquidations validated, (c) exception queue items resolved or listed, (d) AR ledger total equals aging total, (e) cash and bank balances reconciled to the bank statement and the reconciliation stored (statement balance, book balance, difference zero, attachment), (f) lock the period. Who closed and when is logged. After closing, only logged correcting entries.

## 9. Audit and retention
- Append-only audit log: user, delegate flag, time, action, entity, entity id, before and after values. Logged: create, update, approve, reject, void, budget revisions, transfers, overrides, carry-overs, period closes, correcting entries, report exports (user, report type, period, time), logins. No update or delete of audit rows, enforced in the database (no UPDATE or DELETE permission, plus a trigger that blocks them).
- Retention: client-visible and billing history 2 years, internal finance records 5 years, then archived, never hard-deleted.
- Only HeadAccountant audits accounts. FinanceManager audits expenses and cash flow.

## 10. Permissions (policy codes)
Policy codes: clients.view, clients.manage, rates.manage, rates.approve, pod.view, pod.validate, invoice.view, invoice.create, invoice.review, invoice.void, ar.view, ar.followup, payment.view, payment.record, payment.validate, exception.resolve, adjustment.view, adjustment.create, adjustment.approve, cash.view, advance.record, advance.approve, disbursement.record, disbursement.approve, liquidation.record, liquidation.validate, liquidation.view, reimbursement.record, reimbursement.validate, reimbursement.approve, budget.propose, budget.approve, budget.manage, period.close, ceo.record, settings.manage, audit.accounts, audit.finance, ai.view, dashboard.view, report.<ReportKey>.
- Accountant: clients.view, clients.manage, rates.manage, pod.view, pod.validate, invoice.view, invoice.create, ar.view, ar.followup, payment.view, payment.record, adjustment.view, advance.record, disbursement.record, liquidation.record, reimbursement.record, ai.view, plus report keys for Invoices, Collections, OutstandingBalances, Aging.
- HeadAccountant: clients.view, rates.approve, pod.view, invoice.view, invoice.review, invoice.void, ar.view, payment.view, adjustment.view, adjustment.create, audit.accounts, ai.view, dashboard.view, plus report keys for Invoices, Collections, OutstandingBalances, Aging, PaymentValidation, Adjustments.
- AssistantFM: advance.record, disbursement.record, liquidation.record, liquidation.validate, liquidation.view, reimbursement.record, reimbursement.validate, budget.propose, plus report key Liquidation.
- FinanceManager: all view policies, payment.validate, exception.resolve, adjustment.approve, advance.approve, disbursement.approve, reimbursement.approve, budget.approve, budget.manage, period.close, ceo.record, settings.manage, audit.finance, ai.view, dashboard.view, cash.view, and ALL report keys.
- Report keys: Invoices, Collections, OutstandingBalances, Aging, PaymentValidation, Adjustments, CashFlow, Liquidation, Expenses, BudgetVsActual, IncomeStatement, FinancialPosition, CashFlowStatement, ChangesInEquity, AfsPackage. The six company statement keys (IncomeStatement through AfsPackage) are FinanceManager only.

## 11. Integrations (all of them)
- Every message carries an idempotency key (waybill number, invoice number or request id). A retry never creates a duplicate. Failed calls are retried (exponential backoff, max 5) and logged in an outbox/inbox table. No integration can ever set an invoice to Paid.
- DMS to FOMS: completed delivery creates a POD record Pending with the duplicate check; failed delivery sets OnHold until re-delivery and a new validated POD; cash advance requests flow both ways and FOMS returns the budget check result (including OverBudgetOverrideNeeded) and the liquidation status (Liquidated or ForCorrection).
- FOMS to STARS: approved invoice endorsement (STARS returns task id, assignee, signed copy, received date, result); payment and document status as two separate fields; overdue or due-soon collection routing with outcome returned (promised date, collected, disputed). A collected outcome never pays an invoice; the payment still goes through the Finance check.
- STARS owns login. FOMS trusts the STARS-issued JWT, maps the employee number to a FOMS user and role, and ends sessions after 15 minutes of inactivity.

## 12. Defaults for open questions (confirm with Speedex; all are settings or easy to change)
- DueSoonDays 7. Follow-ups before escalation: 3. Aging buckets as in section 3. Discount cap 10%. Alert percentage 80%. CSH-09 threshold: none. Fuel surcharge added after VAT. Valuation 1%. Payroll out of scope. Direct disbursements count in budget Actual at release; reimbursements count in budget Actual when Paid; accrual expense is recognized at approval for reimbursements and disbursements (payable until paid). Limited balance sheet only. Print layout matches the current Speedex invoice format.
