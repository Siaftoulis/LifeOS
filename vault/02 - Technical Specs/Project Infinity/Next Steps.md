# Next Steps | Project Infinity

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Project Infinity|Project Infinity]]

## 1. Backend Implementation (Beyond Stubs)
- **Vocabulary/Trivia Engine:** The Go Daemon must automatically scrape or generate (perhaps via a local LLM or a predefined massive SQLite dictionary) the "Word of the Day" and "Trivia of the Day" at exactly midnight local time.
- **Progress Tracking:** Store historical completions in the `DailyWords` table to ensure words are not repeated within a year.

## 2. Data Interconnectivity & Relationships
- **Link to Point Star System:** Daily engagement here guarantees a baseline `+3 Star Points` (+1 Word, +2 Trivia) to motivate daily app openings.
- **Link to Knowledge Base:** The Trivia facts could be exported to the Obsidian Vault as "Zettelkasten" atomic notes.

## 3. Open Design Questions
1. Do you want Project Infinity to expand into other daily domains (e.g., "Math Problem of the Day" or "Coding Challenge")?
2. Should the system pause generating new words if the user hasn't logged in for a week, or keep cycling?
