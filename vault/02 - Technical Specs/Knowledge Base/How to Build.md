# How to Build | Knowledge Base

This document outlines the step-by-step coding directives and architectural wiring instructions for developer subagents to implement the Knowledge Base.

---

## 1. Step-by-Step Implementation Flow

### Step 1: Go Daemon Notes Indexer (Subagent Gamma)
1. **Directory Allocation:** Create the module handlers in `backend/host-daemon/internal/kb/`.
2. **Metadata Scan Runner:** Write Go code parsing Obsidian tags from file headers:
   ```go
   func ScanFrontmatterTags(filePath string) ([]string, error) {
       content, err := os.ReadFile(filePath)
       if err != nil {
           return nil, err
       }
       return parseYAMLMetadata(content) // regexp tags extractor
   }
   ```
3. **Graph Calculation Engine:** Map wiki-links coordinates compiling dependency structures.

### Step 2: SQLite Drift Schema Migration (Subagent Beta)
1. **Table Mappings:** Add `KnowledgeTopicsTable` and `KnowledgeRelationshipsTable` declarations in `client/lib/database/tables.dart`.
2. **SQLite Compilation:** Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **DAO Integration:** Define queries returning topic groups filtered by category variables.

### Step 3: Flutter Directory Grid UI (Subagent Beta)
1. **Everforest Colors:**
   - Scaffold canvas: `EverforestColors.bg0`.
   - Folders view: `EverforestColors.bg1`.
   - Separators: 1px border lines in `EverforestColors.bg2`.
   - Text highlights: `EverforestColors.fg` (headers), `grey` (details).
2. **Directory Explorer:** Build dynamic grids rendering folder cards.

### Step 4: Flashcards Trigger Interface (Subagent Alpha)
1. **Review Bridge Hooks:** Bind study tags toggle checks to active review queues:
   - Call `FlashcardModule.generateDeck(topicId)` upon user toggle events.
2. **Dirty Mark:** Set `is_dirty = 1` to command immediate Tailscale synchronization sync loops.
