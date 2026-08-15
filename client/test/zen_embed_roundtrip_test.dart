import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/plugins/markdown/zen_embed_block.dart';
import '../lib/presentation/theme/zen_markdown_bridge.dart';

void main() {
  test('embed line round-trips through markdown as a zen_embed node', () {
    final doc = markdownToDocument('Note text\n\n![[photos]]\n\n[[maps]]');
    final converted = ZenMarkdownBridge.applyEmbedBlocks(doc);

    final embeds = converted.root.children
        .where((n) => n.type == ZenEmbedKeys.type)
        .toList();
    expect(embeds.length, 2, reason: 'expected two embeds');
    expect(
      embeds.map((n) => n.attributes[ZenEmbedKeys.module]),
      ['photos', 'maps'],
    );

    final markdown = documentToMarkdown(
      converted,
      customParsers: const [ZenEmbedNodeParser()],
    );
    expect(markdown, contains('![[photos]]'));
    expect(markdown, contains('![[maps]]'));
    expect(markdown, contains('Note text'));
  });

  test('unknown module line stays a plain paragraph', () {
    final doc = markdownToDocument('[[nope]]');
    final converted = ZenMarkdownBridge.applyEmbedBlocks(doc);
    expect(converted.root.children.single.type, ParagraphBlockKeys.type);
    expect(
      converted.root.children.single.delta?.toPlainText(),
      '[[nope]]',
    );
  });

  test('plain wiki links are untouched', () {
    final doc = markdownToDocument('Visit [[some page]] today');
    final converted = ZenMarkdownBridge.applyEmbedBlocks(doc);
    expect(converted.root.children.single.type, ParagraphBlockKeys.type);
  });

  test('embed height round-trips through markdown', () {
    final doc = ZenMarkdownBridge.applyEmbedBlocks(
      markdownToDocument('![[photos|300]]'),
    );
    final embed = doc.root.children.single;
    expect(embed.type, ZenEmbedKeys.type);
    expect(embed.attributes[ZenEmbedKeys.height], 300);

    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser()],
    );
    expect(markdown.trim(), '![[photos|300]]');
  });

  test('embed without height exports bare and defaults to 200', () {
    final doc = ZenMarkdownBridge.applyEmbedBlocks(
      markdownToDocument('![[photos]]'),
    );
    final embed = doc.root.children.single;
    expect(zenEmbedHeightOf(embed), ZenEmbedKeys.defaultHeight);

    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser()],
    );
    expect(markdown.trim(), '![[photos]]');
  });

  test('resized height persists through markdown round-trip', () {
    final doc = Document(
      root: Node(
        type: PageBlockKeys.type,
        children: [
          zenEmbedNode(module: 'photos', height: 420),
          zenEmbedNode(module: 'maps'),
        ],
      ),
    );

    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser()],
    );
    final back = ZenMarkdownBridge.applyEmbedBlocks(
      markdownToDocument(markdown),
    );
    expect(zenEmbedHeightOf(back.root.children[0]), 420);
    expect(zenEmbedHeightOf(back.root.children[1]), ZenEmbedKeys.defaultHeight);
  });

  test('embed block moves up and down among siblings', () async {
    final editorState = EditorState(
      document: Document(
        root: Node(
          type: PageBlockKeys.type,
          children: [
            paragraphNode(text: 'a'),
            zenEmbedNode(module: 'photos'),
            paragraphNode(text: 'b'),
          ],
        ),
      ),
    );
    Node embed() => editorState.document.root.children
        .firstWhere((n) => n.type == ZenEmbedKeys.type);

    await moveZenEmbedBlock(editorState, embed(), 1);
    expect(
      editorState.document.root.children.map((n) => n.type).toList(),
      [
        ParagraphBlockKeys.type,
        ParagraphBlockKeys.type,
        ZenEmbedKeys.type,
      ],
    );

    await moveZenEmbedBlock(editorState, embed(), -1);
    await moveZenEmbedBlock(editorState, embed(), -1);
    expect(
      editorState.document.root.children.map((n) => n.type).toList(),
      [
        ZenEmbedKeys.type,
        ParagraphBlockKeys.type,
        ParagraphBlockKeys.type,
      ],
    );
  });

  test('entity ref with spaces and slashes round-trips', () {
    final doc = ZenMarkdownBridge.applyEmbedBlocks(
      markdownToDocument('![[notes|01 - Tiles/Home]]\n\n![[movies|m3]]'),
    );
    final embeds = doc.root.children
        .where((n) => n.type == ZenEmbedKeys.type)
        .toList();
    expect(embeds.length, 2);
    expect(embeds[0].attributes[ZenEmbedKeys.module], 'notes');
    expect(embeds[0].attributes[ZenEmbedKeys.ref], '01 - Tiles/Home');
    expect(embeds[1].attributes[ZenEmbedKeys.ref], 'm3');
    expect(embeds.every((n) => n.attributes[ZenEmbedKeys.height] == null), isTrue);

    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser()],
    );
    expect(markdown, contains('![[notes|01 - Tiles/Home]]'));
    expect(markdown, contains('![[movies|m3]]'));

    final back = ZenMarkdownBridge.applyEmbedBlocks(
      markdownToDocument(markdown),
    );
    final refs = back.root.children
        .where((n) => n.type == ZenEmbedKeys.type)
        .map((n) => n.attributes[ZenEmbedKeys.ref])
        .toList();
    expect(refs, ['01 - Tiles/Home', 'm3']);
  });

  test('image line becomes an image block and round-trips as markdown', () {
    final md = 'before\n\n![](https://server/api/media/photo.jpg)\n\n'
        '![[/api/v1/gallery/stream?file=map.png]]\n\nafter';
    final doc = ZenMarkdownBridge.applyImageEmbeds(
      ZenMarkdownBridge.applyEmbedBlocks(markdownToDocument(md)),
    );

    final images = doc.root.children
        .where((n) => n.type == ImageBlockKeys.type)
        .toList();
    expect(images.length, 2, reason: 'expected two image blocks');
    expect(
      images[0].attributes[ImageBlockKeys.url],
      'https://server/api/media/photo.jpg',
    );
    expect(
      images[1].attributes[ImageBlockKeys.url],
      '/api/v1/gallery/stream?file=map.png',
    );

    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser(), ZenImageNodeParser()],
    );
    expect(markdown, contains('![](https://server/api/media/photo.jpg)'));
    expect(
      markdown,
      contains('![](/api/v1/gallery/stream?file=map.png)'),
      reason: 'encoder normalizes to markdown image syntax, url must survive',
    );
    expect(markdown, contains('before'));
    expect(markdown, contains('after'));
  });

  test('non-image url stays plain text', () {
    final md = '![](https://server/api/media/note.md)\n\n'
        '![alt](somepage.pdf)';
    final doc = ZenMarkdownBridge.applyImageEmbeds(
      markdownToDocument(md),
    );
    expect(doc.root.children.every((n) => n.type == ParagraphBlockKeys.type), isTrue);
  });

  test('image block encodes with url (not the broken image_src key)', () {
    final doc = Document(
      root: Node(
        type: PageBlockKeys.type,
        children: [imageNode(url: 'https://server/x.webp')],
      ),
    );
    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser(), ZenImageNodeParser()],
    );
    expect(markdown.trim(), '![](https://server/x.webp)');
  });

  test('embed coexists with tables, code blocks, callouts and lists', () {
    const md = '''
# Heading

| col a | col b |
| --- | --- |
| 1 | 2 |

```dart
void main() {}
```

- [ ] todo item

> quote

![[photos|280]]
''';
    final doc = ZenMarkdownBridge.applyEmbedBlocks(markdownToDocument(md));
    final markdown = documentToMarkdown(
      doc,
      customParsers: const [ZenEmbedNodeParser()],
    );
    final back = ZenMarkdownBridge.applyEmbedBlocks(
      markdownToDocument(markdown),
    );

    final types = back.root.children.map((n) => n.type).toList();
    expect(types, contains('heading'));
    expect(types, contains('table'));
    expect(types, contains('code'));
    expect(types, contains('todo_list'));
    expect(types, contains('quote'));
    expect(types, contains(ZenEmbedKeys.type));
    expect(
      back.root.children
          .firstWhere((n) => n.type == ZenEmbedKeys.type)
          .attributes[ZenEmbedKeys.height],
      280,
    );
  });
}
