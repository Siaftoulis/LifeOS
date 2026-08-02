import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../block_component/callout_block_component/callout_block_component.dart';
import '../block_component/code_block_component/code_block_component.dart';
import '../block_component/toggle_block_component/toggle_block_component.dart';

final heading1MenuItem = SelectionMenuItem(
  name: 'Heading 1',
  icon: (editorState, isSelected, style) => const Icon(Icons.title, size: 18),
  keywords: ['heading 1', 'h1', 'title'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      headingNode(level: 1, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final heading2MenuItem = SelectionMenuItem(
  name: 'Heading 2',
  icon: (editorState, isSelected, style) => const Icon(Icons.title, size: 16),
  keywords: ['heading 2', 'h2', 'subtitle'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      headingNode(level: 2, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final heading3MenuItem = SelectionMenuItem(
  name: 'Heading 3',
  icon: (editorState, isSelected, style) => const Icon(Icons.title, size: 14),
  keywords: ['heading 3', 'h3', 'subheading'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      headingNode(level: 3, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final bulletedListMenuItem = SelectionMenuItem(
  name: 'Bulleted list',
  icon: (editorState, isSelected, style) => const Icon(Icons.format_list_bulleted, size: 16),
  keywords: ['bullet', 'bulleted list', 'list'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      bulletedListNode(delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final numberedListMenuItem = SelectionMenuItem(
  name: 'Numbered list',
  icon: (editorState, isSelected, style) => const Icon(Icons.format_list_numbered, size: 16),
  keywords: ['numbered', 'numbered list', 'number'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      numberedListNode(delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final todoListMenuItem = SelectionMenuItem(
  name: 'To-do list',
  icon: (editorState, isSelected, style) => const Icon(Icons.check_box_outlined, size: 16),
  keywords: ['todo', 'task', 'checkbox'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      todoListNode(checked: false, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final quoteMenuItem = SelectionMenuItem(
  name: 'Quote',
  icon: (editorState, isSelected, style) => const Icon(Icons.format_quote, size: 16),
  keywords: ['quote', 'blockquote'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      quoteNode(delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final dividerMenuItem = SelectionMenuItem(
  name: 'Divider',
  icon: (editorState, isSelected, style) => const Icon(Icons.remove, size: 16),
  keywords: ['divider', 'line', 'hr'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      dividerNode(),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final calloutMenuItem = SelectionMenuItem(
  name: 'Callout',
  icon: (editorState, isSelected, style) => const Icon(Icons.info_outline, size: 16, color: Color(0xFF7E57C2)),
  keywords: ['callout', 'note', 'info'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      calloutNode(delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final codeBlockMenuItem = SelectionMenuItem(
  name: 'Code Block',
  icon: (editorState, isSelected, style) => const Icon(Icons.code, size: 16, color: Color(0xFFA7C080)),
  keywords: ['code', 'codeblock', 'snippet'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      codeBlockNode(delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final toggleListMenuItem = SelectionMenuItem(
  name: 'Toggle List',
  icon: (editorState, isSelected, style) => const Icon(Icons.arrow_right, size: 16, color: Color(0xFFDB9D63)),
  keywords: ['toggle', 'toggle list', 'collapsible'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      toggleListNode(delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final tableMenuItem = SelectionMenuItem(
  name: 'Table',
  icon: (editorState, isSelected, style) => const Icon(Icons.table_chart, size: 16, color: Color(0xFF83C5BE)),
  keywords: ['table', 'grid', 'rows', 'columns'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      Node(
        type: 'table',
        attributes: {'rows': 2, 'cols': 2},
      ),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);



final imageMenuItem = SelectionMenuItem(
  name: 'Image',
  icon: (editorState, isSelected, style) => const Icon(Icons.image, size: 16, color: Color(0xFFE29578)),
  keywords: ['image', 'photo', 'picture', 'img'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      imageNode(url: ''),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final zenSelectionMenuItems = [
  heading1MenuItem,
  heading2MenuItem,
  heading3MenuItem,
  bulletedListMenuItem,
  numberedListMenuItem,
  todoListMenuItem,
  quoteMenuItem,
  dividerMenuItem,
  calloutMenuItem,
  codeBlockMenuItem,
  toggleListMenuItem,
  tableMenuItem,
  imageMenuItem,
];


final customAppFlowySlashCommand = CharacterShortcutEvent(
  key: 'show_slash_menu',
  character: '/',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;

    final context = node.context;
    if (context != null && context.mounted) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(offset.dx, offset.dy + 24, offset.dx + 220, offset.dy + 300),
          color: const Color(0xFF263238),
          items: zenSelectionMenuItems.map((item) {
            return PopupMenuItem(
              onTap: () {
                final dummyService = _DummySelectionMenuService();
                item.handler(editorState, dummyService, context);
              },
              child: Row(
                children: [
                  item.icon(editorState, false, SelectionMenuStyle.light),
                  const SizedBox(width: 10),
                  Text(item.name, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }).toList(),
        );
      }
    }
    return true;
  },
);

class _DummySelectionMenuService extends SelectionMenuService {
  @override
  void dismiss() {}
  @override
  Future<void> show() async {}
  @override
  (double?, double?, double?, double?) getPosition() => (null, null, null, null);

  @override
  Alignment get alignment => Alignment.topLeft;
  @override
  Offset get offset => Offset.zero;
  @override
  SelectionMenuStyle get style => SelectionMenuStyle.light;
}







