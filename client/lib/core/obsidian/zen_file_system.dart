import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../api_client.dart';

/// Cross-platform virtual file system for the Zen editor.
///
/// [NativeZenFileSystem] (desktop/mobile) maps onto the real OS filesystem.
/// [WebZenFileSystem] (browser) keeps a virtual directory tree in a key-value
/// cache: files are keys without a trailing '/', directories carry a trailing
/// '/' marker key. On web the cache is only a mirror — every mutation is
/// pushed to the daemon's zen.db (/api/v1/zen/fs/*), so the data lives 100%
/// on the server and survives a browser refresh. Paths use '/' separators.
class FileNode {
  final String name;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;

  FileNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.children,
  });
}

abstract class ZenFileSystem {
  static ZenFileSystem instance = kIsWeb
      ? WebZenFileSystem()
      : NativeZenFileSystem();

  /// Pulls the server state into the local cache (web only; no-op elsewhere).
  /// Must be awaited before touching the tree so local edits don't clobber
  /// what the server already has.
  Future<void> ensureLoaded() async {}

  /// Idempotent: creates [path] (and parents) if missing.
  void createDirectory(String path);
  bool exists(String path);
  bool isDirectory(String path);

  /// Recursive listing of [path]; empty list if missing.
  List<FileNode> scanDirectory(String path);
  String? readFile(String path);
  void writeFile(String path, String content);

  /// Deletes a file, or a directory recursively.
  void delete(String path);
  void rename(String from, String to);

  /// Copies a file, or a directory recursively.
  void copy(String from, String to);

  List<String> listWorkspaces(String vaultPath) {
    final names = <String>[];
    for (final e in scanDirectory('$vaultPath/workspaces')) {
      if (e.isDirectory && !e.name.startsWith('.')) names.add(e.name);
    }
    names.sort();
    return names;
  }

  void createWorkspace(String vaultPath, String name) =>
      createDirectory('$vaultPath/workspaces/$name');

  void deleteWorkspace(String vaultPath, String name) =>
      delete('$vaultPath/workspaces/$name');
}

class NativeZenFileSystem extends ZenFileSystem {
  @override
  void createDirectory(String path) => Directory(path).createSync(recursive: true);

  @override
  bool exists(String path) =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;

  @override
  bool isDirectory(String path) =>
      FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;

  @override
  List<FileNode> scanDirectory(String path) {
    final nodes = <FileNode>[];
    try {
      final entities = Directory(path).listSync();
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.toLowerCase().compareTo(b.path.toLowerCase());
      });

      for (final entity in entities) {
        final name = entity.uri.pathSegments.last.isEmpty
            ? entity.uri.pathSegments[entity.uri.pathSegments.length - 2]
            : entity.uri.pathSegments.last;
        if (name.startsWith('.')) continue;
        nodes.add(entity is Directory
            ? FileNode(
                name: name,
                path: entity.path,
                isDirectory: true,
                children: scanDirectory(entity.path),
              )
            : FileNode(
                name: name,
                path: entity.path,
                isDirectory: false,
                children: [],
              ));
      }
    } catch (e) {
      debugPrint('Error scanning directory $path: $e');
    }
    return nodes;
  }

  @override
  String? readFile(String path) =>
      File(path).existsSync() ? File(path).readAsStringSync() : null;

  @override
  void writeFile(String path, String content) =>
      File(path).writeAsStringSync(content);

  @override
  void delete(String path) {
    if (isDirectory(path)) {
      Directory(path).deleteSync(recursive: true);
    } else {
      File(path).deleteSync();
    }
  }

  @override
  void rename(String from, String to) {
    if (isDirectory(from)) {
      Directory(from).renameSync(to);
    } else {
      File(from).renameSync(to);
    }
  }

  @override
  void copy(String from, String to) {
    if (isDirectory(from)) {
      Directory(to).createSync(recursive: true);
      for (final entity in Directory(from).listSync()) {
        final name = entity.path.split(RegExp(r'[/\\]')).last;
        copy(entity.path, '$to/$name');
      }
    } else {
      File(from).copySync(to);
    }
  }
}

class _PendingOp {
  final String op;
  final Map<String, dynamic> payload;
  _PendingOp(this.op, this.payload);
}

/// Web filesystem backed by the daemon: the cache map is rebuilt from
/// /api/v1/zen/fs/list on [ensureLoaded], and every mutation applies to the
/// cache immediately (snappy UI) then replays to the server in order. Failed
/// mutations stay queued and retry every 15s until the daemon is reachable.
/// A plain Map can be injected for tests (pure in-memory, no server).
// ponytail: cache + ordered queue, single-user scale. Multi-tab web editing
// would need the sync/CRDT path (like native) — revisit if tabs grow.
class WebZenFileSystem extends ZenFileSystem {
  WebZenFileSystem({Map<String, String>? store})
      : _store = store ?? <String, String>{},
        _serverBacked = store == null;

  final Map<String, String> _store;
  final bool _serverBacked;
  final List<_PendingOp> _pending = [];
  bool _flushing = false;
  Timer? _retryTimer;

  String _norm(String path) => path.replaceAll('\\', '/');

  @override
  Future<void> ensureLoaded() async {
    if (!_serverBacked) return;
    await _pullFromServer();
    await _flushPending();
  }

  Future<void> _pullFromServer() async {
    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/zen/fs/list')
          as Map<String, dynamic>;
      _store.clear();
      for (final raw in res['nodes'] as List) {
        final m = raw as Map<String, dynamic>;
        if ((m['is_directory'] as num).toInt() == 1) {
          _store['${m['path']}/'] = '';
        }
      }
      for (final raw in res['documents'] as List) {
        final m = raw as Map<String, dynamic>;
        _store[m['path'] as String] = m['text_content'] as String;
      }
      debugPrint('[ZenWebFS] pulled ${res['nodes']?.length ?? 0} nodes from server');
    } catch (e) {
      debugPrint('[ZenWebFS] server pull failed: $e');
    }
  }

  void _queue(String op, Map<String, dynamic> payload) {
    _applyLocal(op, payload);
    if (!_serverBacked) return;
    _pending.add(_PendingOp(op, payload));
    _flushPending();
  }

  Future<void> _flushPending() async {
    if (!_serverBacked || _flushing) return;
    _flushing = true;
    while (_pending.isNotEmpty) {
      final op = _pending.first;
      try {
        await ApiClient.instance
            .postDaemon('/api/v1/zen/fs/${op.op}', op.payload);
        _pending.removeAt(0);
      } catch (_) {
        break; // daemon unreachable: keep the rest queued, retry later
      }
    }
    _flushing = false;
    if (_pending.isNotEmpty) {
      _retryTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
        _flushPending();
        if (_pending.isEmpty) {
          _retryTimer?.cancel();
          _retryTimer = null;
        }
      });
    }
  }

  void _applyLocal(String op, Map<String, dynamic> payload) {
    switch (op) {
      case 'write':
        _store[_norm(payload['path'] as String)] = payload['content'] as String;
        break;
      case 'mkdir':
        _store['${_norm(payload['path'] as String)}/'] = '';
        break;
      case 'delete':
        final p = _norm(payload['path'] as String);
        for (final key in _store.keys
            .where((k) => _norm(k) == p || _norm(k).startsWith('$p/'))
            .toList()) {
          _store.remove(key);
        }
        break;
      case 'rename':
        final f = _norm(payload['from'] as String);
        final t = _norm(payload['to'] as String);
        for (final key in _store.keys
            .where((k) => _norm(k) == f || _norm(k).startsWith('$f/'))
            .toList()) {
          final value = _store.remove(key)!;
          final suffix = _norm(key).substring(f.length);
          _store['$t$suffix'] = value;
        }
        break;
      case 'copy':
        final f = _norm(payload['from'] as String);
        final t = _norm(payload['to'] as String);
        for (final key in _store.keys
            .where((k) => _norm(k) == f || _norm(k).startsWith('$f/'))
            .toList()) {
          final suffix = _norm(key).substring(f.length);
          _store['$t$suffix'] = _store[key]!;
        }
        break;
    }
  }

  @override
  void createDirectory(String path) => _queue('mkdir', {'path': _norm(path)});

  @override
  bool exists(String path) {
    final p = _norm(path);
    return _store.containsKey(p) || _store.containsKey('$p/');
  }

  @override
  bool isDirectory(String path) => _store.containsKey('${_norm(path)}/');

  @override
  List<FileNode> scanDirectory(String path) {
    final norm = _norm(path);
    final prefix = norm.endsWith('/') ? norm : '$norm/';
    final byName = <String, bool>{};
    for (final rawKey in _store.keys) {
      final key = _norm(rawKey);
      if (!key.startsWith(prefix) || key.length == prefix.length) continue;
      final rest = key.substring(prefix.length);
      final parts = rest.split('/');
      var name = parts.first;
      final isDir = parts.length > 1 || rest.endsWith('/');
      if (isDir) {
        name = name.endsWith('/') ? name.substring(0, name.length - 1) : name;
      }
      if (name.isEmpty || name.startsWith('.')) continue;
      byName[name] = isDir;
    }

    final names = byName.keys.toList()..sort((a, b) {
        final aIsDir = byName[a]!;
        final bIsDir = byName[b]!;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    return names.map((name) {
      final childPath = '$prefix$name';
      return FileNode(
        name: name,
        path: childPath,
        isDirectory: byName[name]!,
        children: byName[name]! ? scanDirectory(childPath) : [],
      );
    }).toList();
  }

  @override
  String? readFile(String path) => _store[_norm(path)];

  @override
  void writeFile(String path, String content) =>
      _queue('write', {'path': _norm(path), 'content': content});

  @override
  void delete(String path) => _queue('delete', {'path': _norm(path)});

  @override
  void rename(String from, String to) =>
      _queue('rename', {'from': _norm(from), 'to': _norm(to)});

  @override
  void copy(String from, String to) =>
      _queue('copy', {'from': _norm(from), 'to': _norm(to)});
}
