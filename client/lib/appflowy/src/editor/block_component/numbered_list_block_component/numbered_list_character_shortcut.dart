import 'package:appflowy_editor/appflowy_editor.dart';

/// Character shortcut event for Numbered List (1. + Space)
final formatNumberedList = CharacterShortcutEvent(
  key: 'format_numbered_list',
  character: ' ',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (RegExp(r'^\d+\.$').hasMatch(text)) {
      final transaction = editorState.transaction;
      transaction.insertNode(
        selection.start.path,
        numberedListNode(delta: Delta()),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

final numberedListCharacterShortcuts = [
  formatNumberedList,
];
