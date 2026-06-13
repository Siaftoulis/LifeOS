# What to Build | Accounting

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Accounting|Accounting]]



This document establishes the technical blueprint, database schemas, API contracts, and UI components to be implemented by the development agents.

---

## 1. Database Architecture (Drift / SQLite)
**Subagent Alpha & Subagent Beta Specifications:**

### Table: `accounting_credentials`
Holds encrypted text values for personal registration numbers.
```sql
CREATE TABLE IF NOT EXISTS accounting_credentials (
    id TEXT PRIMARY KEY,               -- UUID string
    label TEXT NOT NULL,               -- e.g., 'Taxisnet', 'AFM', 'AMKA'
    encrypted_username BLOB,           -- AES-GCM encrypted byte array
    encrypted_password BLOB,           -- AES-GCM encrypted byte array
    updated_at INTEGER NOT NULL,       -- Unix millisecond timestamp
    synced_at INTEGER,                 -- Nullable sync timestamp
    is_dirty INTEGER DEFAULT 0         -- Local mutation flag
);
```

### Table: `accounting_documents`
Holds metadata and encrypted binary paths for scanned official paperwork.
```sql
CREATE TABLE IF NOT EXISTS accounting_documents (
    id TEXT PRIMARY KEY,               -- UUID string
    title TEXT NOT NULL,               -- e.g., 'ID Card Scan 2026'
    encrypted_filepath TEXT NOT NULL,  -- Encrypted local relative path
    file_extension TEXT NOT NULL,      -- e.g., 'pdf', 'png'
    updated_at INTEGER NOT NULL,       -- Unix millisecond timestamp
    synced_at INTEGER,                 -- Nullable sync timestamp
    is_dirty INTEGER DEFAULT 0         -- Local mutation flag
);
```

---

## 2. Daemon API Contracts (JSON-RPC)
**Subagent Gamma Specifications:**

### Endpoint: `Accounting.GetCredentials`
Requests decrypted credential fields.
*   **Request Payload:**
    ```json
    {
      "jsonrpc": "2.0",
      "method": "Accounting.GetCredentials",
      "params": {
        "pin_hash": "64_character_sha256_hash"
      },
      "id": 1
    }
    ```
*   **Response Payload:**
    ```json
    {
      "jsonrpc": "2.0",
      "result": {
        "credentials": [
          {
            "id": "uuid_string",
            "label": "AFM",
            "decrypted_value": "123456789"
          }
        ]
      },
      "id": 1
    }
    ```

### Endpoint: `Accounting.DecryptDocument`
Decrypts and serves document binary streams locally.
*   **Request Payload:**
    ```json
    {
      "jsonrpc": "2.0",
      "method": "Accounting.DecryptDocument",
      "params": {
        "document_id": "uuid_string",
        "pin_hash": "64_character_sha256_hash"
      },
      "id": 2
    }
    ```
*   **Response Payload:**
    ```json
    {
      "jsonrpc": "2.0",
      "result": {
        "raw_bytes_base64": "base64_encoded_decrypted_stream..."
      },
      "id": 2
    }
    ```

---

## 3. UI Component Registry
**Subagent Beta Specifications:**

- `AccountingView` (`client/lib/presentation/widgets/accounting_view.dart`): Main panel housing the document grid and credentials list.
- `GovernmentCredentialCard` (`client/lib/presentation/widgets/gov_credential_card.dart`): Outlined container displaying individual credentials with tap-to-reveal functionality.
- `SecureDocumentCard` (`client/lib/presentation/widgets/secure_document_card.dart`): Grid block for PDFs and images showing preview thumbnails only after successful PIN verification.
- `SecurityPinCurtain` (`client/lib/presentation/widgets/security_pin_curtain.dart`): Screen overlay that intercepts touch inputs and requests the system passcode.
