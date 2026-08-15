import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import '../../../theme/everforest_colors.dart';
import '../../../plugins/markdown/zen_embed_block.dart';

class ZenLinkState {
  static String workspacePath = 'vault';
}

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
        final vaultDir = Directory(ZenLinkState.workspacePath);
        List<String> noteNames = [];
        if (vaultDir.existsSync()) {
          noteNames = vaultDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.md') || f.path.endsWith('.json'))
              .where((f) => !f.path.contains('${Platform.pathSeparator}.dart_tool'))
              .where((f) => !f.path.contains('${Platform.pathSeparator}workspaces${Platform.pathSeparator}'))
              .map((f) => f.path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '').replaceAll('.json', ''))
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        }

        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final pos = renderBox.localToGlobal(Offset.zero);
          showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(pos.dx, pos.dy + 24, pos.dx + 260, pos.dy + 380),
            color: const Color(0xFF242B2E),
            items: [
              for (final name in noteNames)
                PopupMenuItem<String>(
                  height: 34,
                  value: 'page:$name',
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 15, color: EverforestColors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (noteNames.isEmpty)
                const PopupMenuItem<String>(
                  enabled: false,
                  height: 34,
                  child: Text(
                    'No pages in this workspace',
                    style: TextStyle(color: EverforestColors.grey, fontSize: 13),
                  ),
                ),
              const PopupMenuDivider(),
              for (final spec in zenEmbedSpecs.values)
                PopupMenuItem<String>(
                  height: 34,
                  value: '${spec.id}:',
                  child: Row(
                    children: [
                      Icon(
                        spec.icon,
                        size: 15,
                        color: EverforestColors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${spec.label} (module)',
                          style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ).then((value) async {
            if (value == null) return;
            final currentSelection = editorState.selection;
            if (currentSelection == null || !currentSelection.isCollapsed) return;
            // Both '[' are already in the document when this runs (the shortcut
            // fires before the character is inserted); only append the tail.
            if (value.endsWith(':')) {
              await _insertZenEmbed(editorState, node, currentSelection, value.substring(0, value.length - 1));
              return;
            }
            final insert = '${value.substring(5)}]]';
            final transaction = editorState.transaction;
            transaction.insertText(
              node,
              currentSelection.start.offset,
              insert,
            );
            await editorState.apply(transaction);
          });
        }
      }
    }
    return false;
  },
);

/// Replaces the typed `[[` with an inline render window for the module.
Future<void> _insertZenEmbed(
  EditorState editorState,
  Node node,
  Selection selection,
  String module,
) async {
  final text = node.delta?.toPlainText() ?? '';
  final offset = selection.start.offset;

  var caret = offset;
  while (caret > 0 && text[caret - 1] == '[') {
    caret--;
  }
  final openBrackets = offset - caret;
  final hasText = text.substring(0, caret).isNotEmpty;

  final transaction = editorState.transaction;
  if (hasText) {
    transaction
      ..deleteText(node, caret, openBrackets)
      ..insertNode(node.path.next, zenEmbedNode(module: module))
      ..afterSelection = Selection.collapsed(Position(path: node.path, offset: caret));
  } else {
    transaction
      ..deleteNode(node)
      ..insertNode(node.path, paragraphNode())
      ..insertNode(node.path.next, zenEmbedNode(module: module))
      ..afterSelection = Selection.collapsed(Position(path: node.path, offset: 0));
  }
  await editorState.apply(transaction);
}
