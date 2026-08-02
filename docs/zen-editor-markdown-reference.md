# Zen Editor — Format Reference (AppFlowy ⇄ Markdown)

Every format the Zen editor supports right now, in both directions.
Engine: `appflowy_editor 1.5.2` markdown codec + character shortcuts, bridged by `client/lib/presentation/theme/zen_markdown_bridge.dart`.
Files are plain Markdown + optional YAML frontmatter. Any tool that reads `.md` reads these files.

## 1. Type it → block (what typing converts)

| Type (then space / close char) | Becomes |
|---|---|
| `# ` | Heading 1 |
| `## ` | Heading 2 |
| `### ` | Heading 3 |
| `- ` | Bulleted list |
| `* ` | Bulleted list |
| `1. ` | Numbered list (auto-renumbers on Enter) |
| `[] ` | Checkbox, unchecked |
| `[x] ` | Checkbox, checked |
| `-[] ` / `-[x] ` | Same, with hyphen prefix |
| `" ` | Quote |
| `---` `***` `___` | Divider |
| `` `text` `` | Inline code |
| `**text**` / `__text__` | Bold |
| `*text*` / `_text_` | Italic |
| `~~text~~` / `~text~` | Strikethrough |
| `--` | Em dash (—) |

Typing shortcuts live in `appflowy_editor-1.5.2/.../shortcuts/character/`.

## 2. Markdown file → editor (import/parse)

| Markdown | Becomes |
|---|---|
| `# ` / `## ` / `### ` | Heading 1 / 2 / 3 |
| `####+ ` (H4, H5, H6) | **Normalized to H3** (app rule in `zen_markdown_bridge.dart:10`) |
| `- ` or `* ` | Bulleted list |
| `1. ` (any number) | Numbered list |
| `- [ ] ` | Checkbox, unchecked |
| `- [x] ` | Checkbox, checked |
| `> ` | Quote |
| `---` (line of dashes) | Divider |
| ` ```lang` … ` ``` ` | Code block (language kept) |
| `![alt](url-or-path)` | Image — **only `.png`, `.jpg`, `.jpeg`**; anything else stays text |
| `[text](url)` | Link (http/https) |
| `\| a \| b \|` table | Table |
| YAML frontmatter | Extracted, kept out of the editor body, re-attached on save |

Inline: `**bold**`, `_italic_`, `*italic*`, `~~strike~~`, `` `code` ``, `<u>underline</u>`, `[text](url)`.

## 3. Editor → Markdown file (export/save)

| Block | Saved as |
|---|---|
| Paragraph | plain text |
| Heading 1–3 | `# ` / `## ` / `### ` |
| Bulleted list | `- ` |
| Numbered list | `1. ` |
| Checkbox off | `- [ ] ` |
| Checkbox on | `- [x] ` |
| Quote | `> ` |
| Code block | ` ```lang` … ` ``` ` |
| Divider | `---` |
| Image | `![alt](url)` |
| Table | `\| a \| b \|` |
| Inline bold | `**text**` |
| Inline italic | `_text_` (single underscore) |
| Inline strikethrough | `~~text~~` |
| Inline underline | `<u>text</u>` |
| Inline code | `` `text` `` |
| Inline link | `[text](url)` |

On save the app prepends the YAML frontmatter (title/tags, etc.) back on top.

## 4. App-specific extras

- `[[note name]]` typed in the editor auto-completes to an Obsidian-style link (custom command in `zen_workspace.dart`).
- Editor toolbar (FloatingToolbar) only exposes: paragraph, headings, markdown formats, quote, bulleted list, numbered list, link.
- No built-in export to PDF yet — markdown is the interchange format; PDF/etc. is a later step.

## 5. Not supported yet (gotchas)

- `###` is the deepest heading that round-trips; H4–H6 collapse to H3.
- Images: only png/jpg/jpeg paths/URLs become image blocks; PDFs/videos links stay as plain text.
- No callouts, footnotes, math (`$$`), or task-list count toggle.
- Numbered lists import with any start number, but on export always write `1. `.
