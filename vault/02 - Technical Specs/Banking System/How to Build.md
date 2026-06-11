# How to Build | Banking System

This document provides step-by-step instructions for implementing the backend PDF parsing algorithms, rollover balance calculations, and Flutter presentation widgets for the Banking System module.

---

## Step 1: Go Backend PDF parser
**Delegated to: Subagent Gamma**

1. Create the package directory: `backend/host-daemon/banking/`.
2. Implement PDF text extraction using a lightweight, standard library (e.g. `github.com/ledongthuc/pdfreader` or native string scraping handlers):
   ```go
   package banking

   import (
       "os"
       "regexp"
       "strconv"
       "github.com/ledongthuc/pdfreader"
   )

   func ExtractBillAmount(pdfPath string) (int64, error) {
       f, r, err := pdfreader.Open(pdfPath)
       if err != nil {
           return 0, err
       }
       defer f.Close()

       // Pattern matching typical Greek invoice currencies: e.g. "ΠΟΣΟ ΠΛΗΡΩΜΗΣ: 186,40"
       re := regexp.MustCompile(`(?:ΠΟΣΟ ΠΛΗΡΩΜΗΣ|ΣΥΝΟΛΟ|Total)\s*[:]*\s*([0-9]+[\.,][0-9]{2})`)
       
       var textContent string
       // Read and extract text page by page
       for i := 1; i <= r.NumPage(); i++ {
           pageText, _ := r.GetPageText(i)
           textContent += pageText
       }

       match := re.FindStringSubmatch(textContent)
       if len(match) < 2 {
           return 0, os.ErrNotExist
       }

       // Sanitize amount format (convert comma decimals to standard floats/cents)
       // return value in cents
       return parseCents(match[1])
   }
   ```

---

## Step 2: Rollover Calculation Engine
**Delegated to: Subagent Gamma**

1. Implement the rollover carry-over adjustment logic:
   ```go
   package banking

   import "math"

   func CalculateTransferTarget(rawBillCents int64, lastMonthSurplus int64) (int64, int64) {
       // Subtract surplus from target
       adjustedTarget := rawBillCents - lastMonthSurplus
       if adjustedTarget < 0 {
           adjustedTarget = 0
       }

       // Round up to nearest €10 increment
       roundedEuro := math.Ceil(float64(adjustedTarget) / 1000.0) * 10.0
       roundedTargetCents := int64(roundedEuro * 100.0)

       // New rollover surplus to save for next month
       newSurplus := roundedTargetCents - adjustedTarget

       return roundedTargetCents, newSurplus
   }
   ```

---

## Step 3: Local SQLite Drift Tables & Code Generation
**Delegated to: Subagent Beta**

1. Create Drift database entities `bank_accounts`, `bank_ledgers`, `bill_logs`, and `banking_rollover` inside `client/lib/database/tables.dart`.
2. Re-run Drift schema generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. Write local SQLite DAO queries inside `client/lib/database/tasks_extension.dart` to calculate the 50/30/20 splits using star points data fetched from the Point Star SQLite cache.

---

## Step 4: Flutter Presentation & Dynamic Split Widget
**Delegated to: Subagent Beta**

1. Design the `BankingDashboardView` layout inside `client/lib/presentation/widgets/`.
2. Apply the **Everforest Minimalist Flat-Line UI** system:
   - Main scaffold background set to `EverforestColors.bg0`.
   - Card panels set to `EverforestColors.bg1` with a `16px` border radius.
   - Clean 1px border lines in `EverforestColors.bg2` around card outlines.
3. Build the `BudgetSplitIndicator` progress bar:
   - Query points ratios from the [[Point Star System]] SQLite cache dynamically.
   - Compute the split percentage for the 30% "silly things" personal allowance based on the active Star Point ratio.
   - Render horizontal progress bars showing allocations with clean highlights.
