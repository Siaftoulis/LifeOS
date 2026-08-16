import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import '../api_client.dart';
import '../database/database.dart';
import 'obsidian/zen_sync_service.dart';
import 'telemetry/telemetry_reporter.dart';

/// Cloud sync for the Zen vault. Pushes locally-dirty ZenNodes/ZenDocuments to
/// the Go daemon and applies whatever the server has that is newer.
class ZenCloudService {
  static final ZenCloudService instance = ZenCloudService._internal();
  ZenCloudService._internal();

  static String get baseUrl => '${ApiClient.instance.daemonUrl}/api/v1/zen';

  int _lastSyncTs = 0;
  bool _syncing = false;
  bool _started = false;
  Timer? _timer;

  final List<String> _pendingDeletes = [];

  void start() {
    if (_started) return;
    _started = true;
    syncNow();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => syncNow());
  }

  /// Stops periodic sync (used by tests so no timer outlives a widget test).
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Called by ZenSyncService when a node is deleted/renamed/moved locally so
  /// the server removes the old path (tombstone) too.
  void registerDelete(String relativePath) {
    if (!_pendingDeletes.contains(relativePath)) _pendingDeletes.add(relativePath);
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    List<String> deletes = const [];
    try {
      final db = AppDatabase.instance;
      final dirtyNodes = await (db.select(db.zenNodes)..where((t) => t.isDirty.equals(1))).get();
      final dirtyDocs = await (db.select(db.zenDocuments)..where((t) => t.isDirty.equals(1))).get();
      deletes = List<String>.from(_pendingDeletes);
      _pendingDeletes.clear();

      final payload = <String, dynamic>{
        'push_nodes': [
          for (final n in dirtyNodes)
            {
              'id': n.id, 'name': n.name, 'path': n.path,
              'is_directory': n.isDirectory, 'parent_id': n.parentId ?? '',
              'created_at': n.createdAt, 'updated_at': n.updatedAt,
            },
        ],
        'push_documents': [
          for (final d in dirtyDocs)
            {'id': d.id, 'node_id': d.nodeId, 'text_content': d.textContent, 'updated_at': d.updatedAt},
        ],
        'delete_paths': deletes,
        'since': _lastSyncTs,
      };

      final res = await ApiClient.instance.postDaemon('/api/v1/zen/sync', payload) as Map<String, dynamic>;

      await _clearDirty(dirtyNodes, dirtyDocs);
      await _applyRemote(res);
      TelemetryReporter.instance.track('zen', 'note_synced', {'nodes': dirtyNodes.length});
      debugPrint('[ZenCloud] sync ok: pushed ${dirtyNodes.length} nodes/${dirtyDocs.length} docs, '
          'got ${(res['nodes'] as List).length} nodes/${(res['documents'] as List).length} docs');
    } catch (e) {
      debugPrint('[ZenCloud] sync failed: $e');
      _pendingDeletes.addAll(deletes);
    } finally {
      _syncing = false;
    }
  }

  Future<void> _clearDirty(List<ZenNode> nodes, List<ZenDocument> docs) async {
    final db = AppDatabase.instance;
    for (final n in nodes) {
      await (db.update(db.zenNodes)..where((t) => t.id.equals(n.id)))
          .write(ZenNodesCompanion(isDirty: const drift.Value(0)));
    }
    for (final d in docs) {
      await (db.update(db.zenDocuments)..where((t) => t.id.equals(d.id)))
          .write(ZenDocumentsCompanion(isDirty: const drift.Value(0)));
    }
  }

  Future<void> _applyRemote(Map<String, dynamic> res) async {
    final db = AppDatabase.instance;
    int maxTs = _lastSyncTs;

    for (final raw in res['nodes'] as List) {
      final m = raw as Map<String, dynamic>;
      final ts = (m['updated_at'] as num).toInt();
      if (ts > maxTs) maxTs = ts;

      final existing = await (db.select(db.zenNodes)..where((t) => t.id.equals(m['id'] as String))).getSingleOrNull();
      if (existing != null && existing.updatedAt > ts) continue;

      await (db.into(db.zenNodes).insertOnConflictUpdate(ZenNodesCompanion(
        id: drift.Value(m['id'] as String),
        name: drift.Value(m['name'] as String),
        path: drift.Value(m['path'] as String),
        isDirectory: drift.Value((m['is_directory'] as num).toInt()),
        parentId: drift.Value((m['parent_id'] as String?) ?? ''),
        createdAt: drift.Value((m['created_at'] as num).toInt()),
        updatedAt: drift.Value(ts),
        isDirty: const drift.Value(0),
      )));
    }

    for (final raw in res['documents'] as List) {
      final m = raw as Map<String, dynamic>;
      final ts = (m['updated_at'] as num).toInt();
      if (ts > maxTs) maxTs = ts;

      final existing = await (db.select(db.zenDocuments)..where((t) => t.id.equals(m['id'] as String))).getSingleOrNull();
      if (existing != null && existing.updatedAt > ts) continue;

      await (db.into(db.zenDocuments).insertOnConflictUpdate(ZenDocumentsCompanion(
        id: drift.Value(m['id'] as String),
        nodeId: drift.Value(m['node_id'] as String),
        textContent: drift.Value(m['text_content'] as String),
        updatedAt: drift.Value(ts),
        isDirty: const drift.Value(0),
      )));

      // Editor reads files, not the DB: persist pulled content to disk too.
      // File mtime = server updatedAt so the vault watcher sees it as
      // unchanged and won't re-mark it dirty (sync loop).
      final node = await (db.select(db.zenNodes)..where((t) => t.id.equals(m['node_id'] as String))).getSingleOrNull();
      if (node != null && node.isDirectory == 0) {
        await _writeToDisk(node.path, m['text_content'] as String, ts);
      }
    }

    for (final rawPath in res['deleted_paths'] as List) {
      final rel = rawPath as String;
      await _deleteLocalNode(rel);
    }

    _lastSyncTs = maxTs;
  }

  Future<void> _writeToDisk(String relPath, String content, int updatedAt) async {
    final vault = ZenSyncService.instance.vaultPath;
    if (vault.isEmpty) return;
    try {
      final full = File('$vault/${relPath.replaceAll('\\', '/')}');
      await full.parent.create(recursive: true);
      await full.writeAsString(content);
      await full.setLastModified(DateTime.fromMillisecondsSinceEpoch(updatedAt));
    } catch (e) {
      debugPrint('[ZenCloud] disk write failed for $relPath: $e');
    }
  }

  Future<void> _deleteLocalNode(String relPath) async {
    final db = AppDatabase.instance;
    final matches = await (db.select(db.zenNodes)
          ..where((t) => t.path.equals(relPath) | t.path.like('$relPath/%')))
        .get();
    final ids = matches.map((n) => n.id).toList();
    if (ids.isEmpty) return;

    for (final id in ids) {
      await (db.delete(db.zenDocuments)..where((t) => t.nodeId.equals(id))).go();
      await (db.delete(db.zenNodes)..where((t) => t.id.equals(id))).go();
    }

    // Remove from local disk too if present inside the vault.
    final vault = ZenSyncService.instance.vaultPath;
    if (vault.isNotEmpty) {
      final full = File('$vault/${relPath.replaceAll('\\', '/')}');
      try {
        if (full.existsSync()) full.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}
