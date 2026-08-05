import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../block_component/callout_block_component/callout_block_component.dart';
import '../block_component/code_block_component/code_block_component.dart';
import '../block_component/toggle_block_component/toggle_block_component.dart';

final heading1MenuItem = SelectionMenuItem(
  name: 'Heading 1',
  icon: (editorState, isSelected, style) => Icon(
    Icons.title,
    size: 18,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.title,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.title,
    size: 14,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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

final heading4MenuItem = SelectionMenuItem(
  name: 'Heading 4',
  icon: (editorState, isSelected, style) => Icon(
    Icons.title,
    size: 13,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
  keywords: ['heading 4', 'h4'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      headingNode(level: 4, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final heading5MenuItem = SelectionMenuItem(
  name: 'Heading 5',
  icon: (editorState, isSelected, style) => Icon(
    Icons.title,
    size: 12,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
  keywords: ['heading 5', 'h5'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      headingNode(level: 5, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final heading6MenuItem = SelectionMenuItem(
  name: 'Heading 6',
  icon: (editorState, isSelected, style) => Icon(
    Icons.title,
    size: 11,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
  keywords: ['heading 6', 'h6'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      headingNode(level: 6, delta: node.delta ?? Delta()),
    );
    transaction.deleteNode(node);
    editorState.apply(transaction);
  },
);

final bulletedListMenuItem = SelectionMenuItem(
  name: 'Bulleted list',
  icon: (editorState, isSelected, style) => Icon(
    Icons.format_list_bulleted,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.format_list_numbered,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.check_box_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.format_quote,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.remove,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.info_outline,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : const Color(0xFF7E57C2),
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.code,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : const Color(0xFFA7C080),
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.arrow_right,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : const Color(0xFFDB9D63),
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.table_chart,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : const Color(0xFF83C5BE),
  ),
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
  icon: (editorState, isSelected, style) => Icon(
    Icons.image,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : const Color(0xFFE29578),
  ),
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
  heading4MenuItem,
  heading5MenuItem,
  heading6MenuItem,
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
    if (context == null || !context.mounted) return false;

    await editorState.insertTextAtPosition('/', position: selection.start);

    _ZenSelectionMenuOverlay.show(
      context: context,
      editorState: editorState,
      items: zenSelectionMenuItems,
    );

    return true;
  },
);

class _ZenSelectionMenuOverlay {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required EditorState editorState,
    required List<SelectionMenuItem> items,
  }) {
    dismiss();

    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) return;

    final rect = selectionRects.first;
    final editorBox = editorState.renderBox;
    if (editorBox == null) return;

    final editorOffset = editorBox.localToGlobal(Offset.zero);
    final top = rect.bottom - editorOffset.dy + 8;
    final left = rect.left - editorOffset.dx;

    editorState.service.keyboardService?.disable(showCursor: true);
    editorState.service.scrollService?.disable();

    _entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => dismiss(),
              child: const SizedBox.expand(),
            ),
            Positioned(
              top: top,
              left: left.clamp(16.0, (editorBox.size.width - 250.0).clamp(16.0, 10000.0)),
              child: Material(
                color: Colors.transparent,
                child: _ZenSelectionMenuWidget(
                  editorState: editorState,
                  items: items,
                  onClose: () => dismiss(),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  static void dismiss() {
    if (_entry != null) {
      _entry?.remove();
      _entry = null;
    }
  }
}

class _ZenSelectionMenuWidget extends StatefulWidget {
  final EditorState editorState;
  final List<SelectionMenuItem> items;
  final VoidCallback onClose;

  const _ZenSelectionMenuWidget({
    required this.editorState,
    required this.items,
    required this.onClose,
  });

  @override
  State<_ZenSelectionMenuWidget> createState() => _ZenSelectionMenuWidgetState();
}

class _ZenSelectionMenuWidgetState extends State<_ZenSelectionMenuWidget> {
  final _focusNode = FocusNode(debugLabel: 'zen_slash_menu_focus');
  final _scrollController = ScrollController();

  int _selectedIndex = 0;
  String _keyword = '';
  List<SelectionMenuItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = List.from(widget.items);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    widget.editorState.service.keyboardService?.enable();
    widget.editorState.service.scrollService?.enable();
    super.dispose();
  }

  void _updateFilter() {
    final query = _keyword.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(widget.items);
      } else {
        _filteredItems = widget.items.where((item) {
          final nameMatch = item.name.toLowerCase().contains(query);
          final keywordMatch = item.keywords.any((k) => k.toLowerCase().contains(query));
          return nameMatch || keywordMatch;
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients || _filteredItems.isEmpty) return;
    const itemHeight = 36.0;
    final targetOffset = _selectedIndex * itemHeight;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension;

    if (targetOffset < _scrollController.offset) {
      _scrollController.jumpTo(targetOffset);
    } else if (targetOffset + itemHeight > _scrollController.offset + viewportHeight) {
      _scrollController.jumpTo((targetOffset + itemHeight - viewportHeight).clamp(0.0, maxScroll));
    }
  }

  void _executeItem(SelectionMenuItem item) {
    _deleteSlashAndKeyword();

    widget.editorState.service.keyboardService?.enable();
    widget.editorState.service.scrollService?.enable();

    final dummyService = _DummySelectionMenuService();
    item.handler(widget.editorState, dummyService, context);
    widget.onClose();
  }

  void _deleteSlashAndKeyword() {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = widget.editorState.getNodeAtPath(selection.start.path);
    final delta = node?.delta;
    if (node == null || delta == null) return;

    final text = delta.toPlainText();
    final offset = selection.start.offset;
    final slashIndex = text.substring(0, offset).lastIndexOf('/');
    if (slashIndex != -1) {
      final transaction = widget.editorState.transaction
        ..deleteText(node, slashIndex, offset - slashIndex);
      widget.editorState.apply(transaction);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      if (_filteredItems.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1 + _filteredItems.length) % _filteredItems.length;
        });
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      if (_filteredItems.isNotEmpty) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredItems.length;
        });
        _scrollToSelected();
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter) {
      if (_filteredItems.isNotEmpty && _selectedIndex < _filteredItems.length) {
        _executeItem(_filteredItems[_selectedIndex]);
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      _deleteSlashAndKeyword();
      widget.onClose();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace) {
      if (_keyword.isNotEmpty) {
        _keyword = _keyword.substring(0, _keyword.length - 1);
        _deleteLastCharFromEditor();
        _updateFilter();
      } else {
        _deleteSlashAndKeyword();
        widget.onClose();
      }
      return KeyEventResult.handled;
    }

    if (event.character != null && event.character!.isNotEmpty && key != LogicalKeyboardKey.tab) {
      final char = event.character!;
      _keyword += char;
      _insertCharToEditor(char);
      _updateFilter();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  void _insertCharToEditor(String char) {
    final selection = widget.editorState.selection;
    if (selection == null) return;
    final node = widget.editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;

    final transaction = widget.editorState.transaction
      ..insertText(node, selection.start.offset, char);
    widget.editorState.apply(transaction);
  }

  void _deleteLastCharFromEditor() {
    final selection = widget.editorState.selection;
    if (selection == null || selection.start.offset == 0) return;
    final node = widget.editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;

    final transaction = widget.editorState.transaction
      ..deleteText(node, selection.start.offset - 1, 1);
    widget.editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF272E33);
    const borderColor = Color(0xFF343F44);
    const textFg = Color(0xFFD3C6AA);
    const selectBg = Color(0xFF343F44);
    const selectFg = Color(0xFFDBBC7F);
    const menuStyle = SelectionMenuStyle(
      selectionMenuBackgroundColor: darkBg,
      selectionMenuItemTextColor: textFg,
      selectionMenuItemIconColor: textFg,
      selectionMenuItemSelectedTextColor: selectFg,
      selectionMenuItemSelectedIconColor: selectFg,
      selectionMenuItemSelectedColor: selectBg,
    );

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Container(
        width: 240,
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _filteredItems.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No matching blocks',
                  style: TextStyle(color: Color(0xFF859289), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _filteredItems.length,
                itemExtent: 36,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  final isSelected = index == _selectedIndex;

                  return InkWell(
                    onTap: () => _executeItem(item),
                    onHover: (hovering) {
                      if (hovering) {
                        setState(() => _selectedIndex = index);
                      }
                    },
                    child: Container(
                      height: 36,
                      color: isSelected ? selectBg : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          item.icon(widget.editorState, isSelected, menuStyle),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                color: isSelected ? selectFg : textFg,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

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









