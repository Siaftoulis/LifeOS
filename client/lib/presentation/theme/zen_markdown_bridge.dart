import 'package:appflowy_editor/appflowy_editor.dart';
import '../../core/obsidian/frontmatter_service.dart';
import '../../plugins/markdown/zen_embed_block.dart';

class ZenMarkdownBridge {
  static ({String? frontmatter, EditorState editorState}) createEditorState(String fullContent) {
    final extracted = FrontmatterService.extractBodyAndFrontmatter(fullContent);
    String body = extracted.body;

    // Normalize H4, H5, H6 headings to H3 so AppFlowyEditor converts them to heading blocks instead of raw text
    body = body.replaceAll(RegExp(r'^####+\s+', multiLine: true), '### ');

    try {
      var document = markdownToDocument(body);
      document = applyEmbedBlocks(document);
      document = applyImageEmbeds(document);
      processHighlights(document.root);
      if (document.root.children.isEmpty) {
        document.root.children.add(paragraphNode());
      }
      return (frontmatter: extracted.frontmatter, editorState: EditorState(document: document));
    } catch (e) {
      var document = Document.blank(withInitialText: false);
      final lines = body.split('\n');
      for (final line in lines) {
        document.root.children.add(paragraphNode(text: line));
      }
      document = applyEmbedBlocks(document);
      document = applyImageEmbeds(document);
      processHighlights(document.root);
      if (document.root.children.isEmpty) {
        document.root.children.add(paragraphNode());
      }
      return (frontmatter: extracted.frontmatter, editorState: EditorState(document: document));
    }
  }

  /// Converts standalone `[[module]]` / `![[module]]` lines into zen_embed
  /// render windows. `![[module|300]]` sets height, `![[module|ref]]` embeds a
  /// single entity. Plain wiki links stay text links.
  static Document applyEmbedBlocks(Document document) {
    final children = <Node>[];
    for (final child in document.root.children) {
      if (child.type == ParagraphBlockKeys.type && child.delta != null) {
        final match =
            zenEmbedLineRegExp.firstMatch(child.delta!.toPlainText().trim());
        if (match != null) {
          final tail = match.group(2);
          final isHeight = tail != null && double.tryParse(tail) != null;
          children.add(
            zenEmbedNode(
              module: match.group(1)!,
              ref: tail != null && !isHeight ? tail : null,
              height: isHeight ? double.tryParse(tail) : null,
            ),
          );
          continue;
        }
      }
      children.add(child);
    }
    return Document(root: Node(type: PageBlockKeys.type, children: children));
  }

  /// Converts standalone `![](url)` / `![[url]]` paragraphs (that the decoder
  /// left as text — it only handles png/jpg/jpeg) into image blocks that load
  /// straight from the (server) url: no upload, the url is the source.
  static Document applyImageEmbeds(Document document) {
    final children = <Node>[];
    for (final child in document.root.children) {
      if (child.type == ParagraphBlockKeys.type && child.delta != null) {
        final url = zenImageUrlOf(child.delta!.toPlainText());
        if (url != null) {
          children.add(imageNode(url: url));
          continue;
        }
      }
      children.add(child);
    }
    return Document(root: Node(type: PageBlockKeys.type, children: children));
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
      final body = documentToMarkdown(
        editorState.document,
        customParsers: const [ZenEmbedNodeParser(), ZenImageNodeParser()],
      );
      return FrontmatterService.combineFrontmatterAndBody(frontmatterHeader, body);
    } catch (e) {
      return '';
    }
  }

  /// Serializes a set of blocks (e.g. a copy selection) to markdown that
  /// [createEditorState]/[customPasteCommand] can parse back losslessly.
  static String exportMarkdownForNodes(List<Node> nodes) {
    // Deep-copy: Node(children: ...) unlinks nodes from their current parent.
    final copies = nodes.map((n) => Node.fromJson(n.toJson())).toList();
    final document = Document(
      root: Node(
        type: PageBlockKeys.type,
        children: copies,
      ),
    );
    var markdown = documentToMarkdown(
      document,
      customParsers: const [_DividerNodeParser(), ZenEmbedNodeParser(), ZenImageNodeParser()],
    );
    // The encoder parsers emit inconsistent trailing newlines; normalize so a
    // divider always sits between blank lines, like the file convention.
    markdown = markdown
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trimRight();
    // The package encoder emits "1. " + node text, and the parser keeps a
    // leading space after "1." — collapsing to a single space round-trips.
    return markdown.replaceAll(RegExp(r'^1\.\s+', multiLine: true), '1. ');
  }
}

class _DividerNodeParser extends NodeParser {
  const _DividerNodeParser();

  @override
  String get id => DividerBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) => '\n---\n\n';
}

/// Matches a standalone `![](url)` or `![[url]]` line where the url points at
/// an image (http(s) or a known image extension).
final RegExp zenImageLineRegExp = RegExp(
  r'^!\[(?:\[[^\]]*\]|[^\]]*)\]\((\S+)\)$|^!\[\[(\S+)\]\]$',
);

/// Extracts the image url if [line] is a standalone image link, else null.
String? zenImageUrlOf(String line) {
  final match = zenImageLineRegExp.firstMatch(line.trim());
  final url = match?.group(1) ?? match?.group(2);
  if (url == null || url.isEmpty) return null;
  final lower = url.toLowerCase();
  final beforeQuery = lower.split('?')[0];
  final query = lower.contains('?') ? lower.split('?')[1] : '';
  const imageExts = ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.svg', '.avif', '.bmp'];
  final hasImageExt = (String s) => imageExts.any((ext) => s.endsWith(ext));
  if (lower.startsWith('http') || lower.startsWith('/')) {
    return hasImageExt(beforeQuery) || hasImageExt(query) ? url : null;
  }
  return hasImageExt(lower) ? url : null;
}

/// Encoder: image blocks round-trip back to `![](url)`. The bundled
/// ImageNodeParser reads `image_src` which image blocks never set, so without
/// this every image would export as `![](null)`.
class ZenImageNodeParser extends NodeParser {
  const ZenImageNodeParser();

  @override
  String get id => ImageBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final url = node.attributes[ImageBlockKeys.url] as String? ?? '';
    return '![]($url)';
  }
}

/// Live transform: typing `![](url)` and closing with `)` turns the line into
/// an image block on the spot, so the note shows the (server) image as you
/// write — same feel as the `[[...]]` embed shortcut.
final zenImageShortcutEvent = CharacterShortcutEvent(
  key: 'zen_image_from_url',
  character: ')',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return false;
    final node = editorState.getNodeAtPath(selection.start.path);
    if (node == null || node.delta == null) return false;
    final text = node.delta!.toPlainText();
    final offset = selection.start.offset;
    if (text.substring(offset).trim().isNotEmpty) return false;
    // The ')' is about to be typed; the whole line must BE the image syntax.
    final url = zenImageUrlOf(text.substring(0, offset) + ')');
    if (url == null) return false;
    final transaction = editorState.transaction
      ..deleteNode(node)
      ..insertNode(node.path, imageNode(url: url))
      // Non-text blocks swallow the cursor and break typing/navigation, so
      // every image leaves a fresh empty paragraph behind.
      ..insertNode(node.path.next, paragraphNode())
      ..afterSelection =
          Selection.collapsed(Position(path: node.path.next, offset: 0));
    await editorState.apply(transaction);
    return true;
  },
);
