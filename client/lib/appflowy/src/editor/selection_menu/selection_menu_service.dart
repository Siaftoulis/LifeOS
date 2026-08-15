import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../plugins/markdown/zen_embed_block.dart';
import '../../../../presentation/theme/zen_markdown_bridge.dart';
import '../entity_embed_picker.dart';
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

final paragraphMenuItem = SelectionMenuItem(
  name: 'Paragraph',
  icon: (editorState, isSelected, style) => Icon(
    Icons.notes,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : style.selectionMenuItemIconColor,
  ),
  keywords: ['paragraph', 'text', 'plain', 'p'],
  handler: (editorState, menuService, style) {
    final selection = editorState.selection;
    if (selection == null) return;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final transaction = editorState.transaction;
    transaction.insertNode(
      selection.start.path,
      paragraphNode(delta: node.delta ?? Delta()),
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
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.purple,
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
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
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
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.orange,
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

final imageMenuItem = SelectionMenuItem(
  name: 'Image',
  icon: (editorState, isSelected, style) => Icon(
    Icons.image,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.orange,
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

String _movieSubtitle(Map<String, dynamic> m) {
  final rating = m['rating'] is num ? (m['rating'] as num).toDouble() : 0.0;
  return '${m['director'] ?? ''} • ${m['year'] ?? ''}'
      '${rating > 0 ? '  ★ ${rating.toStringAsFixed(1)}' : ''}'
      '  [${m['status'] ?? ''}]';
}

String _bookSubtitle(Map<String, dynamic> b) {
  return '${b['author'] ?? ''} • '
      '${b['current_page'] ?? 0}/${b['total_pages'] ?? 0} p.'
      '  [${b['status'] ?? ''}]';
}

String _trackSubtitle(Map<String, dynamic> t) {
  return '${t['artist'] ?? ''} • ${t['album'] ?? ''}';
}

String _noteSubtitle(Map<String, dynamic> n) {
  return n['path'] as String? ?? '';
}

String _photoSubtitle(Map<String, dynamic> p) {
  return '${p['title'] ?? p['filename'] ?? ''} • ${p['source'] ?? ''}';
}

String _pinSubtitle(Map<String, dynamic> p) {
  final lat = p['lat'] is num ? (p['lat'] as num).toStringAsFixed(4) : '';
  final lon = p['lon'] is num ? (p['lon'] as num).toStringAsFixed(4) : '';
  return '${p['type'] ?? ''} • $lat, $lon';
}

Future<void> _insertEntityEmbed(
  EditorState editorState,
  BuildContext context,
  String module,
  Widget dialog,
) async {
  final id = await showDialog<String>(context: context, builder: (_) => dialog);
  if (id == null || id.isEmpty) return;
  final selection = editorState.selection;
  if (selection == null) return;
  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null) return;
  final transaction = editorState.transaction
    ..insertNode(selection.start.path, zenEmbedNode(module: module, ref: id))
    ..deleteNode(node);
  editorState.apply(transaction);
}

final movieEmbedMenuItem = SelectionMenuItem(
  name: 'Movie',
  icon: (editorState, isSelected, style) => Icon(
    Icons.movie_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
  ),
  keywords: ['movie', 'film', 'embed', 'watch'],
  handler: (editorState, menuService, context) => _insertEntityEmbed(
    editorState,
    context,
    'movies',
    EntityEmbedPickerDialog(
      endpoint: '/api/v1/movies',
      title: 'Embed a movie',
      icon: Icons.movie_outlined,
      statuses: const ['WATCHED', 'AVAILABLE'],
      subtitleOf: _movieSubtitle,
    ),
  ),
);

final bookEmbedMenuItem = SelectionMenuItem(
  name: 'Book',
  icon: (editorState, isSelected, style) => Icon(
    Icons.menu_book_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
  ),
  keywords: ['book', 'read', 'embed'],
  handler: (editorState, menuService, context) => _insertEntityEmbed(
    editorState,
    context,
    'books',
    EntityEmbedPickerDialog(
      endpoint: '/api/v1/books',
      title: 'Embed a book',
      icon: Icons.menu_book_outlined,
      subtitleOf: _bookSubtitle,
    ),
  ),
);

final musicEmbedMenuItem = SelectionMenuItem(
  name: 'Music',
  icon: (editorState, isSelected, style) => Icon(
    Icons.music_note_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
  ),
  keywords: ['music', 'track', 'song', 'embed'],
  handler: (editorState, menuService, context) => _insertEntityEmbed(
    editorState,
    context,
    'music',
    EntityEmbedPickerDialog(
      endpoint: '/api/v1/music/tracks',
      title: 'Embed a track',
      icon: Icons.music_note_outlined,
      subtitleOf: _trackSubtitle,
    ),
  ),
);

final noteEmbedMenuItem = SelectionMenuItem(
  name: 'Note',
  icon: (editorState, isSelected, style) => Icon(
    Icons.description_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
  ),
  keywords: ['note', 'vault', 'markdown', 'embed'],
  handler: (editorState, menuService, context) => _insertEntityEmbed(
    editorState,
    context,
    'notes',
    EntityEmbedPickerDialog(
      endpoint: '/api/v1/notes',
      title: 'Embed a note',
      icon: Icons.description_outlined,
      subtitleOf: _noteSubtitle,
    ),
  ),
);

final photoEmbedMenuItem = SelectionMenuItem(
  name: 'Photo',
  icon: (editorState, isSelected, style) => Icon(
    Icons.photo_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
  ),
  keywords: ['photo', 'image', 'gallery', 'embed'],
  handler: (editorState, menuService, context) => _insertEntityEmbed(
    editorState,
    context,
    'photos',
    EntityEmbedPickerDialog(
      endpoint: '/api/v1/gallery/assets',
      title: 'Embed a photo',
      icon: Icons.photo_outlined,
      subtitleOf: _photoSubtitle,
    ),
  ),
);

final pinEmbedMenuItem = SelectionMenuItem(
  name: 'Map',
  icon: (editorState, isSelected, style) => Icon(
    Icons.map_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.green,
  ),
  keywords: ['map', 'pin', 'place', 'location', 'geofence', 'embed'],
  handler: (editorState, menuService, context) => _insertEntityEmbed(
    editorState,
    context,
    'maps',
    EntityEmbedPickerDialog(
      endpoint: '/api/v1/radar/geofences',
      title: 'Embed a location',
      icon: Icons.map_outlined,
      subtitleOf: _pinSubtitle,
    ),
  ),
);

final templateMenuItem = SelectionMenuItem(
  name: 'Template',
  icon: (editorState, isSelected, style) => Icon(
    Icons.description_outlined,
    size: 16,
    color: isSelected ? style.selectionMenuItemSelectedIconColor : EverforestColors.purple,
  ),
  keywords: ['template', 'preset', 'daily', 'journal', 'meeting', 'review'],
  handler: (editorState, menuService, context) => _insertTemplate(editorState, context),
);

const noteTemplates = <String, String>{
  'Daily Journal': '# Daily Journal\n\n## Wins\n\n## Tasks\n\n## Notes\n\n',
  'Meeting Notes':
      '# Meeting Notes\n\n**Date:**\n\n## Agenda\n\n- \n\n## Decisions\n\n## Action Items\n\n- [ ] \n\n',
  'Book Review':
      '# Book Review\n\n**Book:**\n\n## Summary\n\n## Favorite Quotes\n\n## Rating\n\n',
  'Weekly Review':
      '# Weekly Review\n\n## Went well\n\n## To improve\n\n## Next week\n\n- [ ] \n\n',
};

Future<void> _insertTemplate(EditorState editorState, BuildContext context) async {
  final selection = editorState.selection;
  if (selection == null) return;
  final name = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: EverforestColors.bg1,
      title: const Text(
        'Insert template',
        style: TextStyle(color: EverforestColors.fg, fontSize: 16),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: noteTemplates.keys
              .map((n) => ListTile(
                    dense: true,
                    title: Text(
                      n,
                      style: const TextStyle(
                          color: EverforestColors.fg, fontSize: 14),
                    ),
                    onTap: () => Navigator.of(context).pop(n),
                  ))
              .toList(),
        ),
      ),
    ),
  );
  if (name == null) return;
  var doc = markdownToDocument(noteTemplates[name]!);
  doc = ZenMarkdownBridge.applyEmbedBlocks(doc);
  var nodes = doc.root.children.toList();
  while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
    nodes.removeAt(0);
  }
  while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
    nodes.removeLast();
  }
  if (nodes.isEmpty) return;
  final node = editorState.getNodeAtPath(selection.start.path);
  if (node == null) return;
  final transaction = editorState.transaction;
  // Deep-copy unlinks nodes from the parsed doc's root before re-inserting.
  nodes = nodes.map((n) => Node.fromJson(n.toJson())).toList();
  var at = [...selection.start.path];
  at[at.length - 1]++;
  for (final n in nodes) {
    transaction.insertNode(at, n);
    at = [...at];
    at[at.length - 1]++;
  }
  if (node.delta?.isEmpty ?? false) transaction.deleteNode(node);
  editorState.apply(transaction);
}

final zenSelectionMenuItems = [
  paragraphMenuItem,
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
  movieEmbedMenuItem,
  bookEmbedMenuItem,
  musicEmbedMenuItem,
  noteEmbedMenuItem,
  photoEmbedMenuItem,
  pinEmbedMenuItem,
  templateMenuItem,
];

class _ZenMobileMenuItem {
  const _ZenMobileMenuItem({
    required this.name,
    required this.icon,
    required this.children,
  });

  final String name;
  final IconData icon;
  final List<SelectionMenuItem> children;
}

final _zenMobileMenuCategories = <_ZenMobileMenuItem>[
  _ZenMobileMenuItem(
    name: 'Text Style',
    icon: Icons.format_size,
    children: [paragraphMenuItem, heading1MenuItem, heading2MenuItem, heading3MenuItem],
  ),
  _ZenMobileMenuItem(
    name: 'List',
    icon: Icons.format_list_bulleted,
    children: [todoListMenuItem, bulletedListMenuItem, numberedListMenuItem],
  ),
  _ZenMobileMenuItem(
    name: 'Toggle',
    icon: Icons.arrow_drop_down_circle_outlined,
    children: [toggleListMenuItem],
  ),
  _ZenMobileMenuItem(
    name: 'File & Media',
    icon: Icons.image,
    children: [imageMenuItem, movieEmbedMenuItem, bookEmbedMenuItem, musicEmbedMenuItem, noteEmbedMenuItem, photoEmbedMenuItem, pinEmbedMenuItem],
  ),
  _ZenMobileMenuItem(
    name: 'Visuals',
    icon: Icons.auto_awesome,
    children: [calloutMenuItem, dividerMenuItem, quoteMenuItem],
  ),
  _ZenMobileMenuItem(
    name: 'Table',
    icon: Icons.table_chart_outlined,
    children: [tableMenuItem],
  ),
  _ZenMobileMenuItem(
    name: 'Advanced',
    icon: Icons.code,
    children: [codeBlockMenuItem],
  ),
];

final _zenMobileFlatItems = [for (final c in _zenMobileMenuCategories) ...c.children];

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

    if (PlatformExtension.isMobile) {
      _ZenMobileSelectionMenuOverlay.show(
        context: context,
        editorState: editorState,
      );
    } else {
      _ZenSelectionMenuOverlay.show(
        context: context,
        editorState: editorState,
        items: zenSelectionMenuItems,
      );
    }

    return true;
  },
);

OverlayEntry? _zenMenuOverlayEntry;

void _dismissZenMenuOverlay() {
  _zenMenuOverlayEntry?.remove();
  _zenMenuOverlayEntry = null;
}

void _showZenMenuOverlay({
  required BuildContext context,
  required EditorState editorState,
  required Widget child,
}) {
  _dismissZenMenuOverlay();

  final selectionService = editorState.service.selectionService;
  final selectionRects = selectionService.selectionRects;
  if (selectionRects.isEmpty) return;

  // selectionRects are in GLOBAL coordinates and the overlay is the
  // full-screen root overlay, so the rects can be used as-is.
  final rect = selectionRects.first;
  final top = rect.bottom + 8;
  final left = rect.left;

  editorState.service.keyboardService?.disable(showCursor: true);
  editorState.service.scrollService?.disable();

  _zenMenuOverlayEntry = OverlayEntry(
    builder: (overlayContext) {
      final screenWidth = MediaQuery.sizeOf(overlayContext).width;
      return Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (_) => _dismissZenMenuOverlay(),
            child: const SizedBox.expand(),
          ),
          Positioned(
            top: top,
            left: left.clamp(16.0, (screenWidth - 250.0).clamp(16.0, 10000.0)),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ],
      );
    },
  );

  Overlay.of(context).insert(_zenMenuOverlayEntry!);
}

void _deleteSlashAndKeyword(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) return;

  final node = editorState.getNodeAtPath(selection.start.path);
  final delta = node?.delta;
  if (node == null || delta == null) return;

  final text = delta.toPlainText();
  final offset = selection.start.offset;
  final slashIndex = text.substring(0, offset).lastIndexOf('/');
  if (slashIndex != -1) {
    final transaction = editorState.transaction
      ..deleteText(node, slashIndex, offset - slashIndex);
    editorState.apply(transaction);
  }
}

void _executeSelectionMenuItem(EditorState editorState, SelectionMenuItem item, BuildContext context) {
  _deleteSlashAndKeyword(editorState);
  // The package wrapper would delete the slash again (deleteSlash=true) and
  // crash on the now-empty node (deleteText with index -1). We handle it above.
  item.deleteSlash = false;

  editorState.service.keyboardService?.enable();
  editorState.service.scrollService?.enable();

  item.handler(editorState, _DummySelectionMenuService(), context);
}

class _ZenSelectionMenuOverlay {
  static void show({
    required BuildContext context,
    required EditorState editorState,
    required List<SelectionMenuItem> items,
  }) {
    _showZenMenuOverlay(
      context: context,
      editorState: editorState,
      child: _ZenSelectionMenuWidget(
        editorState: editorState,
        items: items,
        onClose: _dismissZenMenuOverlay,
      ),
    );
  }
}

class _ZenMobileSelectionMenuOverlay {
  static void show({
    required BuildContext context,
    required EditorState editorState,
  }) {
    _showZenMenuOverlay(
      context: context,
      editorState: editorState,
      child: _ZenMobileSelectionMenuWidget(
        editorState: editorState,
        onClose: _dismissZenMenuOverlay,
      ),
    );
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
    _executeSelectionMenuItem(widget.editorState, item, context);
    widget.onClose();
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
      _deleteSlashAndKeyword(widget.editorState);
      widget.onClose();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace) {
      if (_keyword.isNotEmpty) {
        _keyword = _keyword.substring(0, _keyword.length - 1);
        _deleteLastCharFromEditor();
        _updateFilter();
      } else {
        _deleteSlashAndKeyword(widget.editorState);
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
    const darkBg = EverforestColors.bg0;
    const borderColor = EverforestColors.bg1;
    const textFg = EverforestColors.fg;
    const selectBg = EverforestColors.bg1;
    const selectFg = EverforestColors.green;
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
                  style: TextStyle(color: EverforestColors.grey, fontSize: 13),
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

class _ZenMobileSelectionMenuWidget extends StatefulWidget {
  const _ZenMobileSelectionMenuWidget({
    required this.editorState,
    required this.onClose,
  });

  final EditorState editorState;
  final VoidCallback onClose;

  @override
  State<_ZenMobileSelectionMenuWidget> createState() => _ZenMobileSelectionMenuWidgetState();
}

class _ZenMobileSelectionMenuWidgetState extends State<_ZenMobileSelectionMenuWidget> {
  static const _bg = EverforestColors.bg0;
  static const _border = EverforestColors.bg1;
  static const _fg = EverforestColors.fg;
  static const _grey = EverforestColors.grey;
  static const _menuStyle = SelectionMenuStyle(
    selectionMenuBackgroundColor: _bg,
    selectionMenuItemTextColor: _fg,
    selectionMenuItemIconColor: _fg,
    selectionMenuItemSelectedTextColor: _fg,
    selectionMenuItemSelectedIconColor: _fg,
    selectionMenuItemSelectedColor: _bg,
  );

  String _keyword = '';
  bool _showCategories = true;
  List<SelectionMenuItem>? _children;

  @override
  void initState() {
    super.initState();
    widget.editorState.selectionNotifier.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.editorState.selectionNotifier.removeListener(_onSelectionChanged);
    widget.editorState.service.keyboardService?.enable();
    widget.editorState.service.scrollService?.enable();
    super.dispose();
  }

  void _onSelectionChanged() {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) return;
    final node = widget.editorState.getNodeAtPath(selection.start.path);
    if (node == null) return;
    final text = node.delta?.toPlainText() ?? '';
    final caret = selection.start.offset;
    final prefix = caret <= text.length ? text.substring(0, caret) : text;
    final slashIndex = prefix.lastIndexOf('/');
    if (slashIndex == -1) {
      widget.onClose();
      return;
    }
    final keyword = prefix.substring(slashIndex + 1);
    if (keyword == _keyword) return;
    setState(() {
      _keyword = keyword;
      _showCategories = keyword.isEmpty;
      _children = null;
    });
  }

  void _openCategory(_ZenMobileMenuItem category) {
    setState(() {
      _showCategories = false;
      _children = category.children;
    });
  }

  void _executeItem(SelectionMenuItem item) {
    _executeSelectionMenuItem(widget.editorState, item, context);
    widget.onClose();
  }

  List<SelectionMenuItem> _searchItems(String keyword) {
    final query = keyword.toLowerCase().trim();
    if (query.isEmpty) return _zenMobileFlatItems;
    return _zenMobileFlatItems.where((item) {
      final nameMatch = item.name.toLowerCase().contains(query);
      final keywordMatch = item.keywords.any((k) => k.toLowerCase().contains(query));
      return nameMatch || keywordMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      constraints: const BoxConstraints(maxHeight: 208),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _showCategories ? _buildCategories() : _buildChildren(),
    );
  }

  Widget _buildCategories() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      padding: const EdgeInsets.all(4),
      childAspectRatio: 2.4,
      children: [for (final c in _zenMobileMenuCategories) _buildCategoryTile(c)],
    );
  }

  Widget _buildCategoryTile(_ZenMobileMenuItem category) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _openCategory(category),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Icon(category.icon, size: 20, color: _fg),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                category.name,
                style: const TextStyle(color: _fg, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: _grey),
          ],
        ),
      ),
    );
  }

  Widget _buildChildren() {
    final items = _searchItems(_keyword);
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'No matching blocks',
          style: TextStyle(color: _grey, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      itemExtent: 48,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => _executeItem(item),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                item.icon(widget.editorState, false, _menuStyle),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(color: _fg, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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









