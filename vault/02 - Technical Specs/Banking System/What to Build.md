# What to Build | Banking System

This document establishes the technical blueprint, database schemas, API contracts, and UI components to be implemented by the development agents.

---

## 1. Database Architecture (Drift / SQLite)
**Subagent Alpha & Subagent Beta Specifications:**

### Table: `bank_accounts`
Holds accounts metadata and balances.
```sql
CREATE TABLE IF NOT EXISTS bank_accounts (
    id TEXT PRIMARY KEY,               -- UUID string
    name TEXT NOT NULL,                -- e.g., 'Primary Eurobank', 'Bills Saver'
    balance_cents INTEGER NOT NULL,    -- Account balance in cents (integer storage)
    updated_at INTEGER NOT NULL,       -- Unix millisecond timestamp
    synced_at INTEGER,                 -- Nullable sync timestamp
    is_dirty INTEGER DEFAULT 0         -- Local mutation flag
);
```

### Table: `bank_ledgers`
Logs manual transactional entries.
```sql
CREATE TABLE IF NOT EXISTS bank_ledgers (
    id TEXT PRIMARY KEY,               -- UUID string
    account_id TEXT NOT NULL,          -- FK to bank_accounts
    amount_cents INTEGER NOT NULL,     -- Signed integer cents (positive = credit, negative = debit)
    transaction_type TEXT NOT NULL,    -- e.g., 'Groceries', 'Allowance', 'Bills'
    date_timestamp INTEGER NOT NULL,   -- Transaction date stamp
    description TEXT,                  -- Optional description
    updated_at INTEGER NOT NULL,       -- Unix millisecond timestamp
    synced_at INTEGER,                 -- Nullable sync timestamp
    is_dirty INTEGER DEFAULT 0,        -- Local mutation flag
    FOREIGN KEY(account_id) REFERENCES bank_accounts(id)
);
```

### Table: `bill_logs`
Logs parsed utility bills.
```sql
CREATE TABLE IF NOT EXISTS bill_logs (
    id TEXT PRIMARY KEY,               -- UUID string
    provider TEXT NOT NULL,            -- e.g., 'DEI', 'Cosmote'
    amount_cents INTEGER NOT NULL,     -- Bill cost in cents
    due_date INTEGER NOT NULL,         -- Unix timestamp due date
    updated_at INTEGER NOT NULL        -- Unix millisecond timestamp
);
```

### Table: `banking_rollover`
Stores the carry-over surplus to deduct from the next month's required transfers.
```sql
CREATE TABLE IF NOT EXISTS banking_rollover (
    key TEXT PRIMARY KEY,              -- e.g., 'bills_carry_over'
    surplus_cents INTEGER NOT NULL,    -- Surplus amount in cents
    updated_at INTEGER NOT NULL        -- Unix millisecond timestamp
);
```

---

## 2. Local Daemon API Contracts (HTTP)
**Subagent Gamma Specifications:**

### Endpoint: `POST /api/v1/banking/parse-pdf`
*   **Request Headers:** `Content-Type: application/pdf`
*   **Request Body:** Raw binary file bytes
*   **Response Payload:**
    ```json
    {
      "provider": "DEI",
      "amount_cents": 18640,
      "due_date": 1781222400000,
      "rounded_target_cents": 20000,
      "rollover_deducted_cents": 1360
    }
    ```

### Endpoint: `GET /api/v1/banking/status`
*   **Response Payload:**
    ```json
    {
      "monthly_income_cents": 100000,
      "total_bills_cents": 18640,
      "rounded_bill_transfer_cents": 20000,
      "rollover_surplus_cents": 1360,
      "allocations": {
        "essentials_cents": 500000,
        "savings_cents": 200000,
        "personal_allowance_user_cents": 178000,
        "personal_allowance_partner_cents": 122000
      }
    }
    ```

---

## 3. UI Component Registry
**Subagent Beta Specifications:**

- `BankingDashboardView` (`client/lib/presentation/widgets/banking_dashboard_view.dart`): Main console interface display.
- `BudgetSplitIndicator` (`client/lib/presentation/widgets/budget_split_indicator.dart`): Flat progress bar indicators showing 50/30/20 division lines.
- `LedgerTransactionCard` (`client/lib/presentation/widgets/ledger_transaction_card.dart`): Compact outlined card presenting transactions.
- `BillPayTrackerCard` (`client/lib/presentation/widgets/bill_pay_tracker_card.dart`): Displays monthly invoice breakdowns and rounded payment suggestions.
