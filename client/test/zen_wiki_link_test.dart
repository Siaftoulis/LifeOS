import 'dart:convert';
import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/appflowy/src/editor/selection_menu/selection_menu_service.dart';
import 'package:lifeos_client/database/preferences_service.dart';
import 'package:lifeos_client/presentation/widgets/zen_workspace.dart';

const _wsName = 'zz_test_ws';
late Directory _wsDir;

void _writeNote(String name, String body) {
  final doc = Document(
    root: Node(
      type: 'page',
      children: [
        if (name == 'Target')
          Node(
            type: HeadingBlockKeys.type,
            attributes: {
              HeadingBlockKeys.level: 1,
              HeadingBlockKeys.delta: (Delta()..insert('Target Page')).toJson(),
            },
          )
        else
          paragraphNode(delta: Delta()..insert(body)),
      ],
    ),
  );
  File('${_wsDir.path}/$name.json').writeAsStringSync(jsonEncode(doc.toJson()));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _wsDir = Directory('vault/workspaces/$_wsName');
    _wsDir.createSync(recursive: true);
    PreferencesService.zenWorkspace.value = _wsName;
  });

  tearDown(() {
    PreferencesService.zenWorkspace.value = '';
    if (_wsDir.existsSync()) {
      _wsDir.deleteSync(recursive: true);
    }
  });

  testWidgets('clicking [[Target]] opens the linked page', (tester) async {
    _writeNote('Home', '[[Target]]');
    _writeNote('Target', '');

    await tester.pumpWidget(const MaterialApp(home: ZenWorkspace()));
    await tester.pumpAndSettle();

    final link = find.textContaining('[[Target]]', findRichText: true);
    expect(link, findsOneWidget);

    await tester.tap(link);
    await tester.pumpAndSettle();

    expect(find.text('Target Page', findRichText: true), findsOneWidget);
  });

  testWidgets('clicking a link to a missing page shows a snackbar', (tester) async {
    _writeNote('Lone', '[[NoSuchPage]]');

    await tester.pumpWidget(const MaterialApp(home: ZenWorkspace()));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('[[NoSuchPage]]', findRichText: true));
    await tester.pump();

    expect(find.text('Page "NoSuchPage" not found'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('table menu item inserts a valid 2x2 table', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(MaterialApp));

    final es = EditorState(
      document: Document(
        root: Node(type: 'page', children: [paragraphNode(delta: Delta()..insert('/table'))]),
      ),
    );
    es.selection = Selection.collapsed(Position(path: [0], offset: 6));

    final node = es.getNodeAtPath([0])!;
    es.apply(es.transaction..deleteText(node, 0, 6));

    tableMenuItem.deleteSlash = false;
    tableMenuItem.handler(es, _DummySelectionMenuService(), ctx);

    final table = es.document.root.children.single;
    expect(table.type, 'table');
    expect(table.attributes['colsLen'], 2);
    expect(table.attributes['rowsLen'], 2);
    expect(table.children.length, 4);
    expect(
      table.children.every(
        (c) =>
            c.type == TableCellBlockKeys.type &&
            c.attributes.containsKey(TableCellBlockKeys.colPosition) &&
            c.attributes.containsKey(TableCellBlockKeys.rowPosition) &&
            c.children.length == 1,
      ),
      isTrue,
    );
    expect(es.selection?.start.path, [0, 0, 0]);

    await tester.pump(const Duration(milliseconds: 250));
  });

  testWidgets('code block menu item inserts a code block with the text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(MaterialApp));

    final es = EditorState(
      document: Document(
        root: Node(type: 'page', children: [paragraphNode(delta: Delta()..insert('/code'))]),
      ),
    );
    es.selection = Selection.collapsed(Position(path: [0], offset: 5));

    final node = es.getNodeAtPath([0])!;
    es.apply(es.transaction..deleteText(node, 0, 5));

    codeBlockMenuItem.deleteSlash = false;
    codeBlockMenuItem.handler(es, _DummySelectionMenuService(), ctx);

    final block = es.document.root.children.single;
    expect(block.type, 'code_block');
    expect(block.delta?.toPlainText(), isEmpty);
    expect(block.attributes['language'], isNotNull);

    await tester.pump(const Duration(milliseconds: 250));
  });
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
