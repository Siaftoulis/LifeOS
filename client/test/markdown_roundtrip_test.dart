import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/presentation/theme/zen_markdown_bridge.dart';

void main() {
  test('markdown file -> paste -> copy -> paste round trips', () {
    final source = File('vault/test_markdown.md').readAsStringSync();

    // paste #1: what the editor builds from the file
    final firstDoc = markdownToDocument(source);
    ZenMarkdownBridge.processHighlights(firstDoc.root);

    // copy: what customCopyCommand puts on the clipboard
    final markdown = ZenMarkdownBridge.exportMarkdownForNodes(
      firstDoc.root.children.toList(),
    );

    // paste #2: re-parsing the copied markdown (as customPasteCommand does)
    final secondDoc = markdownToDocument(markdown);
    ZenMarkdownBridge.processHighlights(secondDoc.root);

    // Match customPasteCommand: leading/trailing empty blocks are trimmed.
    List<Node> trimEmpty(List<Node> children) {
      var start = 0, end = children.length;
      while (start < end && children[start].delta?.isEmpty == true) start++;
      while (end > start && children[end - 1].delta?.isEmpty == true) end--;
      return children.sublist(start, end);
    }

    _expectSame(
      trimEmpty(secondDoc.root.children),
      trimEmpty(firstDoc.root.children),
    );
  });
}

void _expectSame(List<Node> aChildren, List<Node> bChildren) {
  if (aChildren.length != bChildren.length) {
    fail('child count differs: ${aChildren.length} vs ${bChildren.length}');
  }
  for (var i = 0; i < aChildren.length; i++) {
    _expectSameNode(aChildren[i], bChildren[i]);
  }
}

void _expectSameNode(Node a, Node b) {
  if (a.type != b.type) {
    fail('type differs: ${a.type} vs ${b.type}\n${a.attributes}\n${b.attributes}');
  }
  final aDelta = a.delta?.toPlainText();
  final bDelta = b.delta?.toPlainText();
  if (aDelta != bDelta) {
    fail('text differs in "${a.type}":\n  got:      "${bDelta}"\n  expected: "${aDelta}"');
  }
  if (a.type == TableBlockKeys.type &&
      (a.attributes['colsLen'] != b.attributes['colsLen'] ||
          a.attributes['rowsLen'] != b.attributes['rowsLen'])) {
    fail('table size differs: ${a.attributes} vs ${b.attributes}');
  }
  final aChecked = a.attributes['checked'];
  final bChecked = b.attributes['checked'];
  if (aChecked != bChecked) {
    fail('checked differs: $aChecked vs $bChecked');
  }
  _expectSame(a.children, b.children);
}
