import 'package:appflowy_editor/appflowy_editor.dart';

/// Character shortcut event for Heading 1 (# + Space)
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
      transaction.insertNode(
        selection.start.path,
        headingNode(level: 1, delta: Delta()),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

/// Character shortcut event for Heading 2 (## + Space)
final formatHeading2 = CharacterShortcutEvent(
  key: 'format_heading_2',
  character: ' ',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (text == '##') {
      final transaction = editorState.transaction;
      transaction.insertNode(
        selection.start.path,
        headingNode(level: 2, delta: Delta()),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

/// Character shortcut event for Heading 3 (### + Space)
final formatHeading3 = CharacterShortcutEvent(
  key: 'format_heading_3',
  character: ' ',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (text == '###') {
      final transaction = editorState.transaction;
      transaction.insertNode(
        selection.start.path,
        headingNode(level: 3, delta: Delta()),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

final headingCharacterShortcuts = [
  formatHeading1,
  formatHeading2,
  formatHeading3,
];
