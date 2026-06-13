# How to Build | Accounting

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Accounting|Accounting]]



This document provides step-by-step instructions for implementing the backend cryptography handlers, API endpoints, and Flutter presentation widgets for the Accounting module.

---

## Step 1: Backend Encryption Logic
**Delegated to: Subagent Gamma**

1. Create the package directory: `backend/host-daemon/crypto/`.
2. Implement key derivation from the user's PIN using PBKDF2:
   ```go
   package crypto

   import (
       "crypto/rand"
       "crypto/sha256"
       "golang.org/x/crypto/pbkdf2"
   )

   func DeriveKey(pin string, salt []byte) []byte {
       return pbkdf2.Key([]byte(pin), salt, 4096, 32, sha256.New)
   }
   ```
3. Implement AES-256-GCM block cipher encryption and decryption logic:
   ```go
   package crypto

   import (
       "crypto/aes"
       "crypto/cipher"
       "crypto/rand"
       "io"
   )

   func Encrypt(data []byte, key []byte) ([]byte, error) {
       block, err := aes.NewCipher(key)
       if err != nil {
           return nil, err
       }
       gcm, err := cipher.NewGCM(block)
       if err != nil {
           return nil, err
       }
       nonce := make([]byte, gcm.NonceSize())
       if _, err := io.ReadFull(rand.Reader, nonce); err != nil {
           return nil, err
       }
       return gcm.Seal(nonce, nonce, data, nil), nil
   }
   ```

---

## Step 2: Local Go Daemon API Handlers
**Delegated to: Subagent Gamma**

1. Register new JSON-RPC routes inside the Go daemon router:
   - Handle decryption of documents from disk path mappings.
   - Safely check the SHA-256 PIN hash against the cached system PIN block (initialized in [[Preferences Setting Tab]]).
2. Expose the government bookmarks routing table for local browser views.

---

## Step 3: Local SQLite Drift Tables & Code Generation
**Delegated to: Subagent Beta**

1. Create Drift database entities `accounting_credentials` and `accounting_documents` inside `client/lib/database/tables.dart`.
2. Re-run Drift schema generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Write local SQLite DAO methods to retrieve credentials and filepaths, and trigger automatic delta syncing queues.

---

## Step 4: Flutter Presentation & PIN Curtain
**Delegated to: Subagent Beta**

1. Design the `AccountingView` layout inside `client/lib/presentation/widgets/`.
2. Apply the **Everforest Minimalist Flat-Line UI** system:
   - Main scaffold background set to `EverforestColors.bg0`.
   - Category cards set to `EverforestColors.bg1` with a `16px` border radius.
   - Clean 1px border lines in `EverforestColors.bg2` around card outlines.
3. Build the `SecurityPinCurtain` overlay:
   - Listen to tap triggers on any `SecureDocumentCard`.
   - Intercept the action, slide up a numeric pad, and request the PIN.
   - If verified, send the decryption JSON-RPC request to the Go daemon and render the decrypted asset.
