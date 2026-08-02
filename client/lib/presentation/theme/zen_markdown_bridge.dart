import 'package:appflowy_editor/appflowy_editor.dart';
import '../../core/obsidian/frontmatter_service.dart';

class ZenMarkdownBridge {
  static ({String? frontmatter, EditorState editorState}) createEditorState(String fullContent) {
    final extracted = FrontmatterService.extractBodyAndFrontmatter(fullContent);
    String body = extracted.body;

    // Normalize H4, H5, H6 headings to H3 so AppFlowyEditor converts them to heading blocks instead of raw text
    body = body.replaceAll(RegExp(r'^####+\s+', multiLine: true), '### ');

    try {
      final document = markdownToDocument(body);
      processHighlights(document.root);
      if (document.root.children.isEmpty) {
        document.root.children.add(paragraphNode());
      }
      return (frontmatter: extracted.frontmatter, editorState: EditorState(document: document));
    } catch (e) {
      final document = Document.blank(withInitialText: false);
      final lines = body.split('\n');
      for (final line in lines) {
        document.root.children.add(paragraphNode(text: line));
      }
      processHighlights(document.root);
      if (document.root.children.isEmpty) {
        document.root.children.add(paragraphNode());
      }
      return (frontmatter: extracted.frontmatter, editorState: EditorState(document: document));
    }
  }

  static void processHighlights(Node root) {
    for (final child in root.children) {
      final delta = child.delta;
      if (delta != null) {
        final newDelta = Delta();
        final jsonList = delta.toJson();
        for (final item in jsonList) {
          if (item is Map<String, dynamic>) {
            final insertData = item['insert'];
            final Map<String, dynamic>? attrs = (item['attributes'] as Map?)?.cast<String, dynamic>();
            if (insertData is String) {
              final regex = RegExp(r'==(.*?)==');
              if (regex.hasMatch(insertData)) {
                int lastIndex = 0;
                for (final match in regex.allMatches(insertData)) {
                  if (match.start > lastIndex) {
                    newDelta.insert(insertData.substring(lastIndex, match.start), attributes: attrs);
                  }
                  final matchText = match.group(1) ?? '';
                  final newAttrs = Map<String, dynamic>.from(attrs ?? {});
                  newAttrs['bg_color'] = '0x40DBBC7F';
                  newDelta.insert(matchText, attributes: newAttrs);
                  lastIndex = match.end;
                }
                if (lastIndex < insertData.length) {
                  newDelta.insert(insertData.substring(lastIndex), attributes: attrs);
                }
              } else {
                newDelta.insert(insertData, attributes: attrs);
              }
            } else {
              newDelta.insert(insertData, attributes: attrs);
            }
          }
        }
        child.attributes[ParagraphBlockKeys.delta] = newDelta.toJson();
      }
      processHighlights(child);
    }
  }

  static String exportMarkdown(EditorState editorState, String? frontmatterHeader) {
    try {
      final body = documentToMarkdown(editorState.document);
      return FrontmatterService.combineFrontmatterAndBody(frontmatterHeader, body);
    } catch (e) {
      return '';
    }
  }
}
