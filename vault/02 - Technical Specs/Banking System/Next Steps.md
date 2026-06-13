# Next Steps | Banking System

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Banking System|Banking System]]

## 1. Backend Implementation (Beyond Stubs)
- **Local CSV/OFX Parsing:** Instead of integrating cloud-based APIs like Plaid/Tink, the Go Daemon will monitor a designated folder for exported CSV/OFX statements from the bank and parse them locally.
- **Secure Credential Vault:** Transition the dummy PIN entry logic to a real secure enclave (e.g., encrypted local SQLite file using `sqlcipher` or OS-level credential managers) for banking passwords.

## 2. Data Interconnectivity & Relationships
- **Link to Accounting:** Bank transactions (withdrawals) must be reconciled against the `AccountingLedger` receipts to find missing invoices.
- **Link to Project Infinity:** Achieving savings goals (e.g., reaching a balance milestone) could unlock major gamification rewards or special virtual items.

## 3. Open Design Questions
1. Will we rely exclusively on manual statement exports (CSV drops), or do you want to explore headless browser scraping (e.g., Puppeteer/Playwright locally) to automate balance fetching?
2. How should we handle multi-currency accounts or cryptocurrency wallets in the schema?
