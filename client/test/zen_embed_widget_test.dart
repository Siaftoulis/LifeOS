import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/plugins/markdown/zen_embed_block.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<EditorState> pumpEditor(
    WidgetTester tester,
    List<Node> children,
  ) async {
    final editorState = EditorState(
      document: Document(root: Node(type: 'page', children: children)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AppFlowyEditor(
          editorState: editorState,
          editorScrollController:
              EditorScrollController(editorState: editorState),
          blockComponentBuilders: {
            ...standardBlockComponentBuilderMap,
            ZenEmbedKeys.type: ZenEmbedBlockComponentBuilder(),
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return editorState;
  }

  List<String> types(EditorState es) =>
      es.document.root.children.map((n) => n.type).toList();

  testWidgets('dragging the resize handle grows the embed and persists height',
      (tester) async {
    final es = await pumpEditor(tester, [
      paragraphNode(text: 'hello'),
      zenEmbedNode(module: 'photos'),
    ]);
    final card = find.byType(ZenEmbedCard);
    expect(card, findsOneWidget);
    expect(zenEmbedHeightOf(es.document.root.children[1]), 200);

    await tester.drag(
      find.descendant(of: card, matching: find.byIcon(Icons.drag_handle)),
      const Offset(0, 140),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // tester.drag consumes kDragSlopDefault (~20px), so 140 - 20 = 120 applied.
    expect(zenEmbedHeightOf(es.document.root.children[1]), 320);
  });

  testWidgets('move buttons reorder the embed among siblings',
      (tester) async {
    final es = await pumpEditor(tester, [
      paragraphNode(text: 'a'),
      zenEmbedNode(module: 'photos'),
      paragraphNode(text: 'b'),
    ]);
    expect(types(es), ['paragraph', 'zen_embed', 'paragraph']);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(types(es), ['paragraph', 'paragraph', 'zen_embed']);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(types(es), ['zen_embed', 'paragraph', 'paragraph']);
  });
}
