import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/command/copy_paste_extension.dart';
import '../../../theme/zen_markdown_bridge.dart';

final wikiLinkRegExp = RegExp(r'\[\[([^\[\]\n]+)\]\]');

final formatDoubleEqualsToHighlight = CharacterShortcutEvent(
  key: 'format double equals to gold highlight',
  character: '=',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed || selection.end.offset < 4) {
      return false;
    }

    final path = selection.end.path;
    final node = editorState.getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return false;
    }

    final plainText = delta.toPlainText();
    if (plainText.length < 4 || plainText[selection.end.offset - 1] != '=') {
      return false;
    }

    final charIndexList = <int>[];
    for (var i = 0; i < plainText.length; i++) {
      if (plainText[i] == '=') {
        charIndexList.add(i);
      }
    }

    if (charIndexList.length < 3) {
      return false;
    }

    final thirdLastCharIndex = charIndexList[charIndexList.length - 3];
    final secondLastCharIndex = charIndexList[charIndexList.length - 2];
    final lastCharIndex = charIndexList[charIndexList.length - 1];

    if (secondLastCharIndex != thirdLastCharIndex + 1 ||
        lastCharIndex == secondLastCharIndex + 1) {
      return false;
    }

    final deletion = editorState.transaction
      ..deleteText(node, lastCharIndex, 1)
      ..deleteText(node, thirdLastCharIndex, 2);
    editorState.apply(deletion);

    final format = editorState.transaction
      ..formatText(
        node,
        thirdLastCharIndex,
        selection.end.offset - thirdLastCharIndex - 3,
        {
          'bg_color': '0x40DBBC7F',
        },
      )
      ..afterSelection = Selection.collapsed(
        Position(
          path: path,
          offset: selection.end.offset - 3,
        ),
      );
    editorState.apply(format);
    editorState.toggledStyle.clear();
    return true;
  },
);

/// Jumps over non-text blocks (images/embeds) that have no selectable text,
/// so arrow navigation never stops on them.
Position? _skipNonText(
  EditorState editorState,
  Position position, {
  required bool upwards,
}) {
  var node = editorState.getNodeAtPath(position.path);
  while (node != null && node.delta == null) {
    node = upwards ? node.previous : node.next;
  }
  if (node == null || node.delta == null) {
    return null;
  }
  final text = node.delta!.toPlainText();
  return upwards
      ? Position(path: node.path, offset: text.length)
      : Position(path: node.path, offset: 0);
}

final customMoveCursorUpCommand = CommandShortcutEvent(
  key: 'custom move cursor upward',
  command: 'arrow up',
  macOSCommand: 'arrow up',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }

    final rects = editorState.selectionRects();
    final currentPosition = selection.end;
    final currentNode = editorState.getNodeAtPath(currentPosition.path);

    Position? upPosition;

    final pos1 = currentPosition.moveVertical(editorState, upwards: true);
    if (pos1 != null && pos1 != currentPosition) {
      upPosition = _skipNonText(editorState, pos1, upwards: true);
    }

    if (upPosition == null && rects.isNotEmpty) {
      final rect = rects.reduce((c, n) => c.top <= n.top ? c : n);
      final testOffsets = [
        rect.topLeft.translate(0, -rect.height * 1.5),
        rect.topLeft.translate(0, -rect.height * 2.0),
        rect.topLeft.translate(0, -rect.height * 2.5 - 10),
        rect.topLeft.translate(0, -32.0),
        rect.topLeft.translate(0, -50.0),
      ];

      for (final testOffset in testOffsets) {
        final candidate = editorState.service.selectionService.getPositionInOffset(testOffset);
        if (candidate != null && candidate != currentPosition) {
          upPosition = candidate;
          break;
        }
      }
    }

    if (upPosition == null && currentNode != null) {
      final prevNode = currentNode.previous;
      if (prevNode != null) {
        upPosition = prevNode.selectable?.end();
      } else if (currentNode.parent != null) {
        final parentPrev = currentNode.parent?.previous;
        upPosition = parentPrev?.selectable?.end();
      }
    }

    if (upPosition != null) {
      editorState.updateSelectionWithReason(
        Selection.collapsed(upPosition),
        reason: SelectionUpdateReason.uiEvent,
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  },
);

final customMoveCursorDownCommand = CommandShortcutEvent(
  key: 'custom move cursor downward',
  command: 'arrow down',
  macOSCommand: 'arrow down',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }

    final rects = editorState.selectionRects();
    final currentPosition = selection.end;
    final currentNode = editorState.getNodeAtPath(currentPosition.path);

    Position? downPosition;

    final pos1 = currentPosition.moveVertical(editorState, upwards: false);
    if (pos1 != null && pos1 != currentPosition) {
      downPosition = _skipNonText(editorState, pos1, upwards: false);
    }

    if (downPosition == null && rects.isNotEmpty) {
      final rect = rects.reduce((c, n) => c.bottom >= n.bottom ? c : n);
      final testOffsets = [
        rect.bottomLeft.translate(0, rect.height * 1.5),
        rect.bottomLeft.translate(0, rect.height * 2.0),
        rect.bottomLeft.translate(0, rect.height * 2.5 + 10),
        rect.bottomLeft.translate(0, 32.0),
        rect.bottomLeft.translate(0, 50.0),
      ];

      for (final testOffset in testOffsets) {
        final candidate = editorState.service.selectionService.getPositionInOffset(testOffset);
        if (candidate != null && candidate != currentPosition) {
          downPosition = candidate;
          break;
        }
      }
    }

    if (downPosition == null && currentNode != null) {
      final nextNode = currentNode.next;
      if (nextNode != null) {
        downPosition = nextNode.selectable?.start();
      } else if (currentNode.parent != null) {
        final parentNext = currentNode.parent?.next;
        downPosition = parentNext?.selectable?.start();
      }
    }

    if (downPosition != null) {
      editorState.updateSelectionWithReason(
        Selection.collapsed(downPosition),
        reason: SelectionUpdateReason.uiEvent,
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  },
);

final customCopyCommand = CommandShortcutEvent(
  key: 'copy as markdown',
  command: 'ctrl+c',
  macOSCommand: 'cmd+c',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null || selection.isCollapsed) {
      return KeyEventResult.ignored;
    }
    // Top-level blocks only; the table keeps its cells. Cells flattened by
    // getNodesInSelection would be serialized twice.
    final originalNodes = editorState
        .getNodesInSelection(selection)
        .where((n) => n.parent?.type == PageBlockKeys.type)
        .toList();
    if (originalNodes.isEmpty) {
      return KeyEventResult.ignored;
    }

    () async {
      // Slice partial first/last blocks to the selection bounds.
      final single = originalNodes.length == 1;
      final first = originalNodes.first;
      final last = originalNodes.last;
      final nodes = originalNodes.toList();
      if (first.delta != null && selection.startIndex > 0) {
        final plain = first.delta!
            .slice(selection.startIndex,
                single ? selection.endIndex : first.delta!.length)
            .toPlainText();
        nodes[0] = paragraphNode(text: plain);
      }
      if (!single && last.delta != null && selection.endIndex < last.delta!.length) {
        final plain = last.delta!
            .slice(0, selection.endIndex)
            .toPlainText();
        nodes[nodes.length - 1] = paragraphNode(text: plain);
      }

      await AppFlowyClipboard.setData(
        text: ZenMarkdownBridge.exportMarkdownForNodes(nodes),
      );
    }();
    return KeyEventResult.handled;
  },
);

final customPasteCommand = CommandShortcutEvent(
  key: 'paste markdown or rich content',
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }

    () async {
      final data = await AppFlowyClipboard.getData();
      final text = data.text;

      if (text != null && text.isNotEmpty) {
        try {
          var doc = markdownToDocument(text);
          doc = ZenMarkdownBridge.applyEmbedBlocks(doc);
          doc = ZenMarkdownBridge.applyImageEmbeds(doc);
          ZenMarkdownBridge.processHighlights(doc.root);
          final nodes = doc.root.children.toList();

          while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
            nodes.removeAt(0);
          }
          while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
            nodes.removeLast();
          }
          // Non-text blocks (images/embeds) swallow the cursor and break
          // typing and arrow navigation, so they always get an empty
          // paragraph to land on.
          if (nodes.isNotEmpty && nodes.last.delta == null) {
            nodes.add(paragraphNode());
          }

          if (nodes.isNotEmpty) {
            await editorState.deleteSelectionIfNeeded();
            if (nodes.length == 1) {
              await editorState.pasteSingleLineNode(nodes.first);
            } else {
              await editorState.pasteMultiLineNodes(nodes);
            }
            return;
          }
        } catch (_) {
          // Fallback to default paste
        }
      }

      await pasteCommand.execute(editorState);
    }();

    return KeyEventResult.handled;
  },
);
