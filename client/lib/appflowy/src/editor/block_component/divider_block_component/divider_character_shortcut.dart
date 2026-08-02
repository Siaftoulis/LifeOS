import 'package:appflowy_editor/appflowy_editor.dart';

/// Character shortcut event for Divider (---)
final formatDivider = CharacterShortcutEvent(
  key: 'format_divider',
  character: '-',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (text == '--') {
      final transaction = editorState.transaction;
      transaction.insertNode(
        selection.start.path,
        dividerNode(),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

final dividerCharacterShortcuts = [
  formatDivider,
];
