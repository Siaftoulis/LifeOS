# Next Steps | Knowledge Base

> [!NOTE]
> **Parent Tile:** [[01 - Tiles/Knowledge Base|Knowledge Base]]

## 1. Backend Implementation (Beyond Stubs)
- **Local File System Watcher:** Implement `fsnotify` in Go to actively monitor the local Obsidian Vault directory for changes, instantly updating the Drift SQLite `NotesIndex` without manual syncs.
- **Full-Text Search (FTS):** Integrate SQLite FTS5 (Full-Text Search) into the Drift database to allow lightning-fast keyword querying across thousands of markdown files directly from the Flutter client.

## 2. Data Interconnectivity & Relationships
- **Link to Obsidian Zen Editor:** The Knowledge Base is the read-only graph/directory view, while the Zen Editor is the active mutation layer. Both point to the exact same local markdown files.
- **Link to Flashcards:** Parsing logic should extract flashcards directly from Knowledge Base entries.

## 3. Open Design Questions
1. Do we want to render a dynamic 3D Force-Directed Graph of your notes in Flutter, similar to Obsidian's local graph view?
2. Should we implement an LLM (e.g., a local `ollama` instance) to automatically summarize and tag notes within the Knowledge Base?
