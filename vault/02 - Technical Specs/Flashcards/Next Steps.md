# Next Steps | Flashcards

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Flashcards|Flashcards]]

## 1. Backend Implementation (Beyond Stubs)
- **Spaced Repetition Algorithm (SRS):** Port a proven SRS algorithm (like Anki's SM-2 or FSRS) into the Go Daemon to calculate the exact `next_review` Unix timestamps based on user difficulty ratings (Easy, Good, Hard, Again).
- **Deck Import/Export:** Implement CSV or `.apkg` (Anki package) parsers to allow bulk importing of flashcard decks directly into the SQLite `Flashcards` table.

## 2. Data Interconnectivity & Relationships
- **Link to Knowledge Base:** Flashcards should ideally be generated *from* the Knowledge Base markdown files (e.g., parsing specific tags like `#flashcard`).
- **Link to Project Infinity:** Reviewing daily flashcards should increment the user's Point Star System balance (e.g., `+1 point per 10 reviews`).

## 3. Open Design Questions
1. Will flashcards remain isolated text-based cards, or do we need to support rich media (images/audio) synced via the local Go server?
2. Should we support bi-directional sync with AnkiWeb, or strictly keep LifeOS as a closed, proprietary SRS system?
