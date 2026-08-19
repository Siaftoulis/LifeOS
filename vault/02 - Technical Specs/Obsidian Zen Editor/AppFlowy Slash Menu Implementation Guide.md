# AppFlowy Slash Menu & Block Architecture Guide

> [!NOTE]
> **Parent Specs:** [[02 - Technical Specs/Obsidian Zen Editor/What to Build|Obsidian Zen Editor Specs]]  
> **Status:** Active Development  
> **Last Updated:** August 2, 2026
> **Implementation Status:** Implemented / Production Live

This specification documents the complete **AppFlowy Slash Menu (`/`) and Markdown Shortcut system** for **LifeOS ZenEditor**. It details all blocks, slash keywords, character shortcuts, Dart handler implementations, and Markdown AST conversions.

---

## 1. Executive Summary & Progress Tracking

| Block Category | Total Blocks | Completed | Status |
| :--- | :--- | :--- | :--- |
| **Basic Blocks** | 11 | 7 / 11 | 🟡 In Progress (Headings, Lists, Paragraph ready) |
| **Toggle & Structured** | 5 | 0 / 5 | ⏳ Pending |
| **Media & File** | 8 | 0 / 8 | ⏳ Pending |
| **Database Views** | 8 | 0 / 8 | ⏳ Pending |
| **Advanced & Inline** | 7 | 0 / 7 | ⏳ Pending |

### Current Step Position: **STEP 3 — Divider, Quote, Code Block & Callout**

---

## 2. Complete Block Specifications & Code Implementation Roadmap

### Category A: Basic Blocks

#### 1. Text / Paragraph
- **Slash Keywords:** `/text`, `/p`, `/paragraph`
- **Shortcut:** Plain typing / Enter key
- **Node Type:** `paragraph`
- **Markdown:** Plain text
- **Implementation Status:** ✅ COMPLETE

#### 2. Heading 1
- **Slash Keywords:** `/h1`, `/heading 1`, `/title`
- **Shortcut:** `# ` + Space
- **Node Type:** `heading` (`level: 1`)
- **Markdown:** `# Title`
- **Implementation Status:** ✅ COMPLETE
- **File:** `client/lib/appflowy/src/editor/block_component/heading_block_component/heading_character_shortcut.dart`

```dart
final formatHeading1 = CharacterShortcutEvent(
  key: 'format_heading_1',
  character: ' ',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (text == '#') {
      final transaction = editorState.transaction;
      transaction.insertNode(selection.start.path, headingNode(level: 1, delta: Delta()));
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);
```

#### 3. Heading 2
- **Slash Keywords:** `/h2`, `/heading 2`, `/subtitle`
- **Shortcut:** `## ` + Space
- **Node Type:** `heading` (`level: 2`)
- **Markdown:** `## Heading 2`
- **Implementation Status:** ✅ COMPLETE

#### 4. Heading 3
- **Slash Keywords:** `/h3`, `/heading 3`, `/subheading`
- **Shortcut:** `### ` + Space
- **Node Type:** `heading` (`level: 3`)
- **Markdown:** `### Heading 3`
- **Implementation Status:** ✅ COMPLETE

#### 5. Bulleted List
- **Slash Keywords:** `/bullet`, `/bulleted list`, `/list`
- **Shortcut:** `- ` or `* ` + Space
- **Node Type:** `bulleted_list`
- **Markdown:** `- Item`
- **Implementation Status:** ✅ COMPLETE
- **File:** `client/lib/appflowy/src/editor/block_component/bulleted_list_block_component/bulleted_list_character_shortcut.dart`

#### 6. Numbered List
- **Slash Keywords:** `/numbered`, `/numbered list`, `/number`
- **Shortcut:** `1. ` + Space
- **Node Type:** `numbered_list`
- **Markdown:** `1. Item`
- **Implementation Status:** ✅ COMPLETE

#### 7. To-do List Checkbox
- **Slash Keywords:** `/todo`, `/task`, `/checkbox`
- **Shortcut:** `[] ` or `[ ] ` + Space
- **Node Type:** `todo_list` (`checked: false`)
- **Markdown:** `- [ ] Task`
- **Implementation Status:** ✅ COMPLETE

#### 8. Divider (Horizontal Rule)
- **Slash Keywords:** `/divider`, `/hr`, `/line`
- **Shortcut:** `---` + Enter
- **Node Type:** `divider`
- **Markdown:** `---`
- **Implementation Status:** 🛠 NEXT STEP (Step 3)

#### 9. Quote
- **Slash Keywords:** `/quote`, `/blockquote`
- **Shortcut:** `> ` + Space
- **Node Type:** `quote`
- **Markdown:** `> Quote text`
- **Implementation Status:** 🛠 NEXT STEP (Step 3)

#### 10. Link to Page (Obsidian Wikilink)
- **Slash Keywords:** `/link`, `/wikilink`, `/page`
- **Shortcut:** `[[`
- **Node Type:** `paragraph` with inline link delta `[[Note Title]]`
- **Markdown:** `[[Note Title]]`
- **Implementation Status:** 🟡 Partial (`_insertLink` available)

#### 11. Document / Embedded Note
- **Slash Keywords:** `/document`, `/embed`
- **Shortcut:** `![[`
- **Node Type:** `embed_document`
- **Markdown:** `![[Note Title]]`
- **Implementation Status:** ⏳ Pending

---

### Category B: Toggle & Structured Blocks

#### 12. Table
- **Slash Keywords:** `/table`, `/grid`
- **Shortcut:** `|`
- **Node Type:** `table`
- **Markdown:** `| Col 1 | Col 2 |\n|---|---|`
- **Implementation Status:** ⏳ Pending

#### 13. Toggle List
- **Slash Keywords:** `/toggle`, `/collapsible`
- **Shortcut:** `> ` + Space (when toggle enabled)
- **Node Type:** `toggle_list`
- **Markdown:** `<details><summary>Title</summary>Content</details>`
- **Implementation Status:** ⏳ Pending

#### 14. Toggle Heading 1 / 2 / 3
- **Slash Keywords:** `/toggle h1`, `/toggle h2`, `/toggle h3`
- **Node Type:** `toggle_heading` (`level: 1..3`)
- **Implementation Status:** ⏳ Pending

---

### Category C: Media & File Blocks

#### 15. Image
- **Slash Keywords:** `/image`, `/img`, `/picture`
- **Shortcut:** `![alt](url)`
- **Node Type:** `image`
- **Markdown:** `![Image](path.png)`
- **Implementation Status:** ✅ Supported in `ZenMarkdownBridge`

#### 16. Photo Gallery
- **Slash Keywords:** `/gallery`, `/photos`
- **Node Type:** `gallery`
- **Implementation Status:** ⏳ Pending

#### 17. Embed Video / Audio / PDF / File
- **Slash Keywords:** `/video`, `/audio`, `/pdf`, `/file`
- **Node Type:** `media_embed` (`type: video|audio|pdf|file`)
- **Markdown:** `![[file.mp4]]`, `![[doc.pdf]]`
- **Implementation Status:** ⏳ Pending

---

### Category D: Database Blocks

#### 18. Grid / Linked Grid
- **Slash Keywords:** `/grid`, `/db`
- **Node Type:** `database_grid`
- **Implementation Status:** ⏳ Pending

#### 19. Kanban / Linked Kanban
- **Slash Keywords:** `/kanban`, `/board`
- **Node Type:** `database_kanban`
- **Implementation Status:** ⏳ Pending

#### 20. Calendar / Linked Calendar / Chart
- **Slash Keywords:** `/calendar`, `/chart`
- **Node Type:** `database_view`
- **Implementation Status:** ⏳ Pending

---

### Category E: Advanced & Inline Blocks

#### 21. Callout (GitHub / Obsidian Alert)
- **Slash Keywords:** `/callout`, `/alert`, `/note`
- **Shortcut:** `> [!NOTE]` + Enter
- **Node Type:** `callout` (`type: note|warning|important|tip`)
- **Markdown:** `> [!NOTE]\n> Text`
- **Implementation Status:** 🛠 NEXT STEP (Step 3)

#### 22. Code Block
- **Slash Keywords:** `/code`, `/developer`
- **Shortcut:** ` ``` ` + Enter
- **Node Type:** `code_block` (`language: dart|go|js|text`)
- **Markdown:** ` ```lang\ncode\n``` `
- **Implementation Status:** 🛠 NEXT STEP (Step 3)

#### 23. Mermaid Diagram
- **Slash Keywords:** `/mermaid`, `/diagram`
- **Shortcut:** ` ```mermaid `
- **Node Type:** `code_block` (`language: mermaid`)
- **Markdown:** ` ```mermaid\ngraph TD;\nA-->B;\n``` `
- **Implementation Status:** ⏳ Pending

#### 24. Math Equation (LaTeX)
- **Slash Keywords:** `/math`, `/latex`, `/equation`
- **Shortcut:** `$$`
- **Node Type:** `math_block`
- **Markdown:** `$$ \sum_{i=1}^n x_i $$`
- **Implementation Status:** ⏳ Pending

---

## 3. Resume Guide & Instructions for Continuing

When resuming work on ZenEditor Slash Menu:

1. **Active Files**:
   - `client/lib/appflowy/src/editor/selection_menu/selection_menu_service.dart` (Slash Menu Items)
   - `client/lib/appflowy/src/editor/block_component/` (Character Shortcuts per block type)
   - `client/lib/presentation/widgets/zen_workspace.dart` (AppFlowyEditor binding)
   - `client/lib/presentation/theme/zen_markdown_bridge.dart` (Markdown AST Codec)

2. **Next Commands to Build**:
   - `Divider` (`---`), `Quote` (`> `), `Code Block` (`` ``` ``), `Callout` (`> [!NOTE]`).

3. **Verification Command**:
   - `flutter analyze client/lib/presentation/widgets/zen_workspace.dart`

