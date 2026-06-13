# Next Steps | Accounting

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Accounting|Accounting]]

## 1. Backend Implementation (Beyond Stubs)
- **Local OCR Engine:** Integrate a local OCR binary (e.g., `tesseract-ocr`) executed via `os/exec` in the Go Daemon to parse receipts offline without cloud APIs.
- **PDF Parsing:** Replace stub parsers with actual Go PDF libraries (e.g., `unidoc` or `pdfcpu`) to extract text and amounts from digital invoices.
- **Database Mapping:** Map the parsed fields to the `AccountingLedger` Drift schema for LWW sync.

## 2. Data Interconnectivity & Relationships
- **Link to Home Management:** Invoice payments (e.g., utility bills) parsed here should automatically update task completion states in the Home Management dashboard.
- **Link to Point Star System:** Successfully scanning and categorizing receipts within 24 hours of purchase could trigger a `+2 Star Points` reward.

## 3. Open Design Questions
1. Do we want to support automated email parsing (e.g., IMAP local sync) to automatically pull PDF invoices into the Accounting system?
2. Should we implement custom categorization rules (Regex-based) to automatically tag expenses (e.g., "S/M" -> "Groceries")?
