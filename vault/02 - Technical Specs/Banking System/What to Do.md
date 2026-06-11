# What to Do | Banking System

This document establishes the exact development task checklists and integration requirements for the Banking System module, delegated as commands to the autonomous subagents.

---

## 1. Subagent Alpha (Lead Architect) Commands
- [ ] **DATA_SCHEMAS.md Update:** Verify that the relational tables, column structures, and index layouts for banking ledgers, parsed bills, and rollover surpluses are documented in `vault/04 - LifeOS DevDocs/DATA_SCHEMAS.md`.
- [ ] **Conflict Resolution Rules:** Verify sync validation schemas for manual transaction ledger logs.
- [ ] **Milestone Logging:** Document all database schema updates, conflict resolution policies, and reward calculations in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) upon completion.

---

## 2. Subagent Beta (Frontend & Local Storage) Commands
- [ ] **Drift Table Definitions:** Generate the Dart models for `BankAccounts`, `BankLedgers`, `BillLogs`, and `BankingRollovers` inside `client/lib/database/` and run the build runner code generator.
- [ ] **UI Presentation Layer:** Build the `BankingDashboardView` inside `client/lib/presentation/widgets/` matching the Everforest Minimalist Flat-Line UI properties:
  - Scaffold wrapper container background set to `EverforestColors.bg0`.
  - Account cards and transaction cards set to `EverforestColors.bg1` with a `16px` border radius.
  - Outlines set to 1px wide in `EverforestColors.bg2` around panels.
  - Text indicators in `EverforestColors.fg` (Beige) and subtext in `EverforestColors.grey`.
- [ ] **Dynamic Budget Splitting Widget:** Implement `BudgetSplitIndicator` showing flat progress indicators for the 50/30/20 allowance distribution:
  - Query points ratios from the [[Point Star System]] SQLite cache dynamically.
  - Scale the 30% "silly things" personal allowance based on the computed ratio.
- [ ] **Change Documentation:** Update the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) with details of all new Drift tables, budget indicators, and UI components created for the Banking System.

---

## 3. Subagent Gamma (Systems, Security & Network) Commands
- [ ] **PDF Bill Extraction Wrapper:** Implement the Go bill PDF parser in `backend/host-daemon/banking/` using a standard PDF library (e.g., `pdfcpu` text extraction handles).
  - Search parsed text lines for known currency patterns (e.g. `Ποσό πληρωμής` or `Σύνολο` in Greek utility invoices).
- [ ] **Rollover Calculation Engine:** Write the calculation routines in Go:
  - Aggregate bill totals and output rounded-up sums.
  - Query the local database for last month's leftover rollover surplus.
  - Adjust the required next-transfer amount downwards by subtracting the rollover surplus, updating the target database entry.
- [ ] **Sync APIs:** Expose HTTP API endpoints on the local sidecar daemon:
  - `POST /api/v1/banking/parse-pdf`: Accepts raw PDF bytes from file watchers.
  - `GET /api/v1/banking/status`: Returns aggregated monthly ledger statistics.
- [ ] **Execution Log Update:** Record details of the Go PDF invoice parser, calculation engine updates, and HTTP status endpoints in the [Step_Trace_Log.md](file:///c:/Users/PDS_Dev/1_Production/Projects/LifeOS/vault/03%20-%20work/Step_Trace_Log.md) before final delivery.
