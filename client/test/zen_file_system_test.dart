import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos_client/core/obsidian/zen_file_system.dart';

void main() {
  group('NativeZenFileSystem', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('zen_fs_test_');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    test('create, scan, read, write, rename, copy, delete, workspaces', () {
      final fs = NativeZenFileSystem();
      final vault = tmp.path;

      fs.createWorkspace(vault, 'alpha');
      fs.createDirectory('$vault/workspaces/alpha/sub');
      fs.writeFile('$vault/workspaces/alpha/a.json', '{"a":1}');
      fs.writeFile('$vault/workspaces/alpha/sub/b.json', '{"b":2}');

      final tree = fs.scanDirectory('$vault/workspaces');
      expect(tree.single.name, 'alpha');
      expect(tree.single.isDirectory, true);
      expect(tree.single.children.map((c) => c.name).toList(), ['sub', 'a.json']);
      expect(fs.readFile('$vault/workspaces/alpha/a.json'), '{"a":1}');
      expect(fs.readFile('$vault/workspaces/alpha/missing.json'), isNull);
      expect(fs.listWorkspaces(vault), ['alpha']);

      fs.rename('$vault/workspaces/alpha', '$vault/workspaces/beta');
      expect(fs.isDirectory('$vault/workspaces/beta'), true);
      expect(fs.exists('$vault/workspaces/beta/a.json'), true);
      expect(fs.exists('$vault/workspaces/alpha'), false);

      fs.copy('$vault/workspaces/beta/a.json', '$vault/workspaces/beta/c.json');
      expect(fs.readFile('$vault/workspaces/beta/c.json'), '{"a":1}');

      fs.deleteWorkspace(vault, 'beta');
      expect(fs.scanDirectory('$vault/workspaces'), isEmpty);
    });
  });

  group('WebZenFileSystem (in-memory store)', () {
    late Map<String, String> store;
    late WebZenFileSystem fs;

    setUp(() {
      store = {};
      fs = WebZenFileSystem(store: store);
    });

    test('create, scan, read, write, rename, copy, delete, workspaces', () {
      fs.createWorkspace('vault', 'alpha');
      fs.writeFile('vault/workspaces/alpha/a.json', '{"a":1}');
      fs.writeFile('vault/workspaces/alpha/sub/b.json', '{"b":2}');
      fs.createDirectory('vault/workspaces/alpha/empty');

      final tree = fs.scanDirectory('vault/workspaces');
      expect(tree.single.name, 'alpha');
      expect(tree.single.isDirectory, true);
      expect(tree.single.children.map((c) => c.name).toList(),
          ['empty', 'sub', 'a.json']);
      final sub = tree.single.children.firstWhere((c) => c.name == 'sub');
      expect(sub.children.single.name, 'b.json');
      expect(fs.readFile('vault/workspaces/alpha/a.json'), '{"a":1}');
      expect(fs.readFile('vault/workspaces/alpha/missing.json'), isNull);
      expect(fs.listWorkspaces('vault'), ['alpha']);
      expect(fs.isDirectory('vault/workspaces/alpha'), true);
      expect(fs.exists('vault/workspaces/alpha/a.json'), true);

      fs.rename('vault/workspaces/alpha', 'vault/workspaces/beta');
      expect(fs.isDirectory('vault/workspaces/beta'), true);
      expect(fs.exists('vault/workspaces/beta/a.json'), true);
      expect(fs.exists('vault/workspaces/beta/sub/b.json'), true);
      expect(fs.exists('vault/workspaces/alpha'), false);

      fs.copy('vault/workspaces/beta/a.json', 'vault/workspaces/beta/c.json');
      expect(fs.readFile('vault/workspaces/beta/c.json'), '{"a":1}');

      fs.delete('vault/workspaces/beta/sub');
      expect(fs.scanDirectory('vault/workspaces/beta').map((n) => n.name),
          ['empty', 'a.json', 'c.json']);

      fs.deleteWorkspace('vault', 'beta');
      expect(fs.scanDirectory('vault/workspaces'), isEmpty);
    });

    test('dotfolders are hidden from scans', () {
      fs.createDirectory('vault/.obsidian');
      fs.createDirectory('vault/pages');
      final names = fs.scanDirectory('vault').map((n) => n.name).toList();
      expect(names, ['pages']);
    });
  });
}
