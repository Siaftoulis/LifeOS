# Zen Editor Test Document

This file exercises the Zen editor: markdown paste, tables, code blocks, and wiki links.

## Headings

### H3 heading
#### H4 heading (normalized to H3)

## Text formatting

**Bold text**, *italic text*, ~~strikethrough~~, `inline code`, and ==gold highlight==.

- bulleted item
- second bullet

1. numbered one
2. numbered two

- [ ] todo unchecked
- [x] todo checked

> A quote block for reference.

---

## Code block

```dart
void main() {
  final message = 'Zen tables & code blocks work';
  print(message);
}
```

## Table

| Feature | Status |
| ------- | ------ |
| Wiki links | working |
| Tables | working |
| Code blocks | working |

## Wiki links

Page link: [[Welcome to Zen Editor]]

Module links (no import needed, opens the existing module):
- [[maps]]
- [[photos]]
- [[books]]
- [[movies]]

Missing page (should show a snackbar): [[This Page Does Not Exist]]

## Paste test

1. Select all of this file (Ctrl+A, Ctrl+C).
2. In the Zen editor, Ctrl+V.
3. Expect: headings, lists, the code block, the table, and the `[[links]]` (blue, underlined) to survive the paste.
