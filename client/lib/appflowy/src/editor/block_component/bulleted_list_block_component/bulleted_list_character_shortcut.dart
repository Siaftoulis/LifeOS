import 'package:appflowy_editor/appflowy_editor.dart';

/// Character shortcut event for Bulleted List (- + Space or * + Space)
final formatBulletedList = CharacterShortcutEvent(
  key: 'format_bulleted_list',
  character: ' ',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (text == '-' || text == '*') {
      final transaction = editorState.transaction;
      transaction.insertNode(
        selection.start.path,
        bulletedListNode(delta: Delta()),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

final bulletedListCharacterShortcuts = [
  formatBulletedList,
];
