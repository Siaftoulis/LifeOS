import 'package:appflowy_editor/appflowy_editor.dart';

/// Character shortcut event for Todo List Checkbox ([] + Space or [ ] + Space)
final formatTodoList = CharacterShortcutEvent(
  key: 'format_todo_list',
  character: ' ',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;
    final text = node.delta?.toPlainText() ?? '';
    if (text == '[]' || text == '[ ]') {
      final transaction = editorState.transaction;
      transaction.insertNode(
        selection.start.path,
        todoListNode(checked: false, delta: Delta()),
      );
      transaction.deleteNode(node);
      await editorState.apply(transaction);
      return true;
    }
    return false;
  },
);

final todoListCharacterShortcuts = [
  formatTodoList,
];
