import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';

final wikiLinkShortcutEvent = CharacterShortcutEvent(
  key: 'wiki_link_autocomplete',
  character: '[',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;

    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null) return false;

    final text = node.delta?.toPlainText() ?? '';
    final offset = selection.start.offset;

    // Check if the preceding character was also '['
    if (offset > 0 && text.length >= offset && text.substring(offset - 1, offset) == '[') {
      final context = node.context;
      if (context != null && context.mounted) {
        final vaultDir = Directory('vault');
        List<String> noteNames = [];
        if (vaultDir.existsSync()) {
          noteNames = vaultDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.md'))
              .map((f) => f.path.split(RegExp(r'[/\\]')).last.replaceAll('.md', ''))
              .toList();
        }

        if (noteNames.isEmpty) {
          noteNames = ['Daily Note', 'Tasks & Projects', 'Ideas', 'Evergreen Notes'];
        }

        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final pos = renderBox.localToGlobal(Offset.zero);
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(pos.dx, pos.dy + 24, pos.dx + 240, pos.dy + 300),
            color: const Color(0xFF263238),
            items: noteNames.map((name) {
              return PopupMenuItem(
                onTap: () async {
                  final transaction = editorState.transaction;
                  transaction.insertText(
                    node,
                    selection.start.offset,
                    '[$name]]',
                  );
                  await editorState.apply(transaction);
                },
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 16, color: Color(0xFFA7C080)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        }
      }
    }
    return false;
  },
);
