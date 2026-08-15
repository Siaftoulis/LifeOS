import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../database/database.dart';
import '../zen_cloud_service.dart';
import 'websocket_sync_service.dart';

class ZenSyncService extends ChangeNotifier {
  static final ZenSyncService instance = ZenSyncService._internal();
  ZenSyncService._internal();

  String _vaultPath = '';
  bool _initialized = false;
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  Timer? _pollTimer;
  Set<String> _knownPaths = {};
  final _uuid = const Uuid();

  String get vaultPath => _vaultPath;

  Future<void> initialize(String vaultPath) async {
    if (_initialized) return; // scan + watch once, service is app-wide
    _initialized = true;
    _vaultPath = vaultPath;
    final dir = Directory(_vaultPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    // 1. Scan filesystem and populate/update DB
    await _scanDirectory(dir);
    _knownPaths = _snapshotPaths();
    
    // 2. Watch for external filesystem changes (recursive watch is not
    // supported on all platforms — Android throws — so fall back to polling).
    try {
      _watchSubscription = dir.watch(recursive: true).listen((event) {
        _handleFileEvent(event);
      });
    } catch (e) {
      debugPrint('ZenSync: recursive watch unavailable ($e) — polling instead');
      _startPolling();
    }
  }

  Set<String> _snapshotPaths() {
    final out = <String>{};
    try {
      for (final entity in Directory(_vaultPath).listSync(recursive: true)) {
        final rel = _getRelativePath(entity.path);
        if (rel.isNotEmpty && !rel.startsWith('.')) out.add(rel);
      }
    } catch (_) {}
    return out;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollScan());
  }

  Future<void> _pollScan() async {
    final dir = Directory(_vaultPath);
    if (!await dir.exists()) return;
    try {
      final seen = <String>{};
      for (final entity in dir.listSync(recursive: true)) {
        final rel = _getRelativePath(entity.path);
        if (rel.isEmpty || rel.startsWith('.')) continue;
        seen.add(rel);
        if (entity is Directory) {
          await _processDirectory(entity);
        } else if (entity is File && entity.path.endsWith('.md')) {
          await _processFile(entity);
        }
      }
      if (_knownPaths.isNotEmpty) {
        for (final rel in _knownPaths) {
          if (seen.contains(rel)) continue;
          // Deleted outside the app (or by another device after pull).
          ZenCloudService.instance.registerDelete(rel);
          final db = AppDatabase.instance;
          await (db.delete(db.zenNodes)..where((t) => t.path.equals(rel))).go();
        }
      }
      _knownPaths = seen;
    } catch (e) {
      debugPrint('ZenSync: poll scan failed: $e');
    }
  }

  Future<void> _scanDirectory(Directory dir) async {
    try {
      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is Directory) {
          await _processDirectory(entity);
        } else if (entity is File && entity.path.endsWith('.md')) {
          await _processFile(entity);
        }
      }
    } catch (e) {
      debugPrint('Error scanning vault directory: $e');
    }
  }

  String _getRelativePath(String fullPath) {
    String rel;
    if (fullPath.startsWith(_vaultPath)) {
      rel = fullPath.substring(_vaultPath.length).replaceAll('\\', '/');
    } else {
      rel = fullPath.replaceAll('\\', '/');
    }
    while (rel.startsWith('/')) {
      rel = rel.substring(1);
    }
    return rel;
  }

  Future<void> _processDirectory(Directory dir) async {
    final relPath = _getRelativePath(dir.path);
    if (relPath.isEmpty) return;

    final db = AppDatabase.instance;
    final existing = await (db.select(db.zenNodes)..where((t) => t.path.equals(relPath))).getSingleOrNull();
    
    if (existing == null) {
      await db.into(db.zenNodes).insert(ZenNodesCompanion(
        id: drift.Value(_uuid.v4()),
        name: drift.Value(dir.uri.pathSegments.lastWhere((e) => e.isNotEmpty)),
        path: drift.Value(relPath),
        isDirectory: const drift.Value(1),
        createdAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        isDirty: const drift.Value(1),
      ));
    }
  }

  Future<void> _processFile(File file) async {
    final relPath = _getRelativePath(file.path);
    final db = AppDatabase.instance;
    final stat = await file.stat();
    
    var node = await (db.select(db.zenNodes)..where((t) => t.path.equals(relPath))).getSingleOrNull();
    
    if (node == null) {
      final nodeId = _uuid.v4();
      await db.into(db.zenNodes).insert(ZenNodesCompanion(
        id: drift.Value(nodeId),
        name: drift.Value(file.uri.pathSegments.last),
        path: drift.Value(relPath),
        isDirectory: const drift.Value(0),
        createdAt: drift.Value(stat.modified.millisecondsSinceEpoch),
        updatedAt: drift.Value(stat.modified.millisecondsSinceEpoch),
        isDirty: const drift.Value(1),
      ));
      
      final content = await file.readAsString();
      await db.into(db.zenDocuments).insert(ZenDocumentsCompanion(
        id: drift.Value(_uuid.v4()),
        nodeId: drift.Value(nodeId),
        textContent: drift.Value(content),
        updatedAt: drift.Value(stat.modified.millisecondsSinceEpoch),
        isDirty: const drift.Value(1),
      ));
    } else {
      // Check if file is newer than db
      if (stat.modified.millisecondsSinceEpoch > node.updatedAt) {
        final content = await file.readAsString();
        final doc = await (db.select(db.zenDocuments)..where((t) => t.nodeId.equals(node.id))).getSingleOrNull();
        
        await db.update(db.zenNodes).replace(node.copyWith(
          updatedAt: stat.modified.millisecondsSinceEpoch,
          isDirty: 1,
        ));
        
        if (doc != null) {
          await db.update(db.zenDocuments).replace(doc.copyWith(
            textContent: content,
            updatedAt: stat.modified.millisecondsSinceEpoch,
            isDirty: 1,
          ));
        } else {
          await db.into(db.zenDocuments).insert(ZenDocumentsCompanion(
            id: drift.Value(_uuid.v4()),
            nodeId: drift.Value(node.id),
            textContent: drift.Value(content),
            updatedAt: drift.Value(stat.modified.millisecondsSinceEpoch),
            isDirty: const drift.Value(1),
          ));
        }
      }
    }
    notifyListeners();
  }

  Future<void> _handleFileEvent(FileSystemEvent event) async {
    if (event is FileSystemModifyEvent || event is FileSystemCreateEvent) {
       final file = File(event.path);
       final dir = Directory(event.path);
       if (await file.exists() && event.path.endsWith('.md')) {
         await _processFile(file);
       } else if (await dir.exists()) {
         await _processDirectory(dir);
       }
    } else if (event is FileSystemDeleteEvent) {
       final relPath = _getRelativePath(event.path);
       final db = AppDatabase.instance;
       ZenCloudService.instance.registerDelete(relPath);
       await (db.delete(db.zenNodes)..where((t) => t.path.equals(relPath))).go();
       notifyListeners();
    }
  }

  // --- API FOR UI --- //

  /// Upserts node+document from an existing file on disk (any extension).
  /// Used by ZenWorkspace which writes files directly; marks the row dirty so
  /// ZenCloudService picks it up on the next sync.
  Future<void> upsertNodeFromDisk(String fullPath) async {
    final file = File(fullPath);
    if (!await file.exists()) return;
    final db = AppDatabase.instance;
    final relPath = _getRelativePath(fullPath);
    final stat = await file.stat();
    final mtime = stat.modified.millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ts = mtime > 0 ? mtime : now;

    var node = await (db.select(db.zenNodes)..where((t) => t.path.equals(relPath))).getSingleOrNull();
    String nodeId;
    if (node == null) {
      nodeId = _uuid.v4();
      await db.into(db.zenNodes).insert(ZenNodesCompanion(
        id: drift.Value(nodeId),
        name: drift.Value(file.uri.pathSegments.last),
        path: drift.Value(relPath),
        isDirectory: const drift.Value(0),
        createdAt: drift.Value(ts),
        updatedAt: drift.Value(ts),
        isDirty: const drift.Value(1),
      ));
    } else {
      nodeId = node.id;
      await db.update(db.zenNodes).replace(node.copyWith(updatedAt: ts, isDirty: 1));
    }

    final content = await file.readAsString();
    final doc = await (db.select(db.zenDocuments)..where((t) => t.nodeId.equals(nodeId))).getSingleOrNull();
    if (doc != null) {
      await db.update(db.zenDocuments).replace(doc.copyWith(
        textContent: content,
        updatedAt: ts,
        isDirty: 1,
      ));
    } else {
      await db.into(db.zenDocuments).insert(ZenDocumentsCompanion(
        id: drift.Value(_uuid.v4()),
        nodeId: drift.Value(nodeId),
        textContent: drift.Value(content),
        updatedAt: drift.Value(ts),
        isDirty: const drift.Value(1),
      ));
    }
    notifyListeners();
  }

  /// Deletes DB rows for a full disk path (used by ZenWorkspace which already
  /// removed the file). Registers the path for cloud deletion. If the path was
  /// a directory, re-upserts its surviving subtree so renamed/moved children
  /// get fresh paths instead of stale ones.
  Future<void> deleteByFullPath(String fullPath) async {
    final relPath = _getRelativePath(fullPath);
    final db = AppDatabase.instance;
    ZenCloudService.instance.registerDelete(relPath);
    final nodesToDelete = await (db.select(db.zenNodes)..where((t) => t.path.equals(relPath) | t.path.like('$relPath/%'))).get();
    for (final node in nodesToDelete) {
      await (db.delete(db.zenNodes)..where((t) => t.id.equals(node.id))).go();
      await (db.delete(db.zenDocuments)..where((t) => t.nodeId.equals(node.id))).go();
    }
    final dir = Directory(fullPath);
    if (dir.existsSync()) {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) {
          await upsertNodeFromDisk(entity.path);
        }
      }
    }
    notifyListeners();
  }

  Future<void> createNode(String parentPath, String name, bool isDirectory, {bool broadcast = true}) async {
    final db = AppDatabase.instance;
    String cleanParent = parentPath;
    while (cleanParent.startsWith('/')) {
      cleanParent = cleanParent.substring(1);
    }
    final relPath = cleanParent.isEmpty ? name : '$cleanParent/$name';
    final fullPath = '$_vaultPath/$relPath';
    
    final nodeId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.into(db.zenNodes).insert(ZenNodesCompanion(
      id: drift.Value(nodeId),
      name: drift.Value(name),
      path: drift.Value(relPath),
      isDirectory: drift.Value(isDirectory ? 1 : 0),
      createdAt: drift.Value(now),
      updatedAt: drift.Value(now),
      isDirty: const drift.Value(1),
    ));

    if (isDirectory) {
      final dir = Directory(fullPath);
      if (!await dir.exists()) await dir.create(recursive: true);
    } else {
      final file = File(fullPath);
      if (!await file.exists()) {
        await file.writeAsString('');
      }
      await db.into(db.zenDocuments).insert(ZenDocumentsCompanion(
        id: drift.Value(_uuid.v4()),
        nodeId: drift.Value(nodeId),
        textContent: const drift.Value(''),
        updatedAt: drift.Value(now),
        isDirty: const drift.Value(1),
      ));
    }
    
    if (broadcast) {
      WebsocketSyncService.instance.broadcastCreateNode('User_${Platform.localHostname}', parentPath, name, isDirectory);
    }
    
    notifyListeners();
  }

  Future<void> updateDocumentContent(String nodeId, String content) async {
    final db = AppDatabase.instance;
    final now = DateTime.now().millisecondsSinceEpoch;

    final doc = await (db.select(db.zenDocuments)..where((t) => t.nodeId.equals(nodeId))).getSingleOrNull();
    if (doc != null) {
      await db.update(db.zenDocuments).replace(doc.copyWith(
        textContent: content,
        updatedAt: now,
        isDirty: 1,
      ));
    }

    final node = await (db.select(db.zenNodes)..where((t) => t.id.equals(nodeId))).getSingleOrNull();
    if (node != null) {
      await db.update(db.zenNodes).replace(node.copyWith(updatedAt: now, isDirty: 1));
      
      final fullPath = '$_vaultPath/${node.path}';
      final file = File(fullPath);
      await file.writeAsString(content); // Sync to file system
    }
    notifyListeners();
  }

  Future<void> saveNote(String notePath, String content) async {
    final relPath = _getRelativePath(notePath);
    try {
      final db = AppDatabase.instance;
      final node = await (db.select(db.zenNodes)..where((t) => t.path.equals(relPath))).getSingleOrNull();

      if (node != null) {
        await updateDocumentContent(node.id, content);
        return;
      }
    } catch (_) {}

    final fullPath = notePath.startsWith(_vaultPath) ? notePath : '$_vaultPath/$relPath';
    final file = File(fullPath);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(content);
  }

  Future<void> deleteNode(String relativePath, {bool broadcast = true}) async {
    final db = AppDatabase.instance;
    final fullPath = '$_vaultPath/$relativePath';

    // 1. Delete from filesystem
    if (Directory(fullPath).existsSync()) {
      Directory(fullPath).deleteSync(recursive: true);
    } else if (File(fullPath).existsSync()) {
      File(fullPath).deleteSync();
    }

    // 2. Delete from DB
    ZenCloudService.instance.registerDelete(relativePath);
    final nodesToDelete = await (db.select(db.zenNodes)..where((t) => t.path.equals(relativePath) | t.path.like('$relativePath/%'))).get();
    for (final node in nodesToDelete) {
      await (db.delete(db.zenNodes)..where((t) => t.id.equals(node.id))).go();
      await (db.delete(db.zenDocuments)..where((t) => t.nodeId.equals(node.id))).go();
    }
    
    if (broadcast) {
      WebsocketSyncService.instance.broadcastDeleteNode('User_${Platform.localHostname}', relativePath);
    }
    
    notifyListeners();
  }

  Future<void> renameNode(String oldRelativePath, String newName, {bool broadcast = true}) async {
    final db = AppDatabase.instance;
    final parts = oldRelativePath.split('/');
    if (parts.isEmpty) return;
    
    final isFile = !Directory('$_vaultPath/$oldRelativePath').existsSync();
    final sanitizedName = isFile && !newName.endsWith('.md') ? '$newName.md' : newName;
    
    parts[parts.length - 1] = sanitizedName;
    final newRelativePath = parts.join('/');
    
    final oldFullPath = '$_vaultPath/$oldRelativePath';
    final newFullPath = '$_vaultPath/$newRelativePath';

    // 1. Rename filesystem
    if (Directory(oldFullPath).existsSync()) {
      Directory(oldFullPath).renameSync(newFullPath);
    } else if (File(oldFullPath).existsSync()) {
      File(oldFullPath).renameSync(newFullPath);
    }

    // 2. Update DB
    final node = await (db.select(db.zenNodes)..where((t) => t.path.equals(oldRelativePath))).getSingleOrNull();
    if (node != null) {
      await db.update(db.zenNodes).replace(node.copyWith(
        name: newName,
        path: newRelativePath,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        isDirty: 1,
      ));

      if (node.isDirectory == 1) {
        final children = await (db.select(db.zenNodes)..where((t) => t.path.like('$oldRelativePath/%'))).get();
        for (final child in children) {
          final newChildPath = child.path.replaceFirst(oldRelativePath, newRelativePath);
          await db.update(db.zenNodes).replace(child.copyWith(
            path: newChildPath,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            isDirty: 1,
          ));
        }
      }
    }
    ZenCloudService.instance.registerDelete(oldRelativePath);
    
    if (broadcast) {
      WebsocketSyncService.instance.broadcastRenameNode('User_${Platform.localHostname}', oldRelativePath, newName);
    }
    
    notifyListeners();
  }

  Future<void> moveNode(String oldRelativePath, String targetParentRelativePath, {bool broadcast = true}) async {
    final db = AppDatabase.instance;
    final fileName = oldRelativePath.split('/').last;
    
    String cleanTargetParent = targetParentRelativePath;
    while (cleanTargetParent.startsWith('/')) {
      cleanTargetParent = cleanTargetParent.substring(1);
    }
    while (cleanTargetParent.endsWith('/')) {
      cleanTargetParent = cleanTargetParent.substring(0, cleanTargetParent.length - 1);
    }
    
    final newRelativePath = cleanTargetParent.isEmpty ? fileName : '$cleanTargetParent/$fileName';
    
    if (oldRelativePath == newRelativePath) return;

    final oldFullPath = '$_vaultPath/$oldRelativePath';
    final newFullPath = '$_vaultPath/$newRelativePath';

    // 1. Rename/move in filesystem
    final file = File(oldFullPath);
    final dir = Directory(oldFullPath);
    if (dir.existsSync()) {
      dir.renameSync(newFullPath);
    } else if (file.existsSync()) {
      file.renameSync(newFullPath);
    }

    // 2. Update DB
    final node = await (db.select(db.zenNodes)..where((t) => t.path.equals(oldRelativePath))).getSingleOrNull();
    if (node != null) {
      await db.update(db.zenNodes).replace(node.copyWith(
        path: newRelativePath,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        isDirty: 1,
      ));

      if (node.isDirectory == 1) {
        final children = await (db.select(db.zenNodes)..where((t) => t.path.like('$oldRelativePath/%'))).get();
        for (final child in children) {
          final newChildPath = child.path.replaceFirst(oldRelativePath, newRelativePath);
          await db.update(db.zenNodes).replace(child.copyWith(
            path: newChildPath,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
            isDirty: 1,
          ));
        }
      }
    }
    ZenCloudService.instance.registerDelete(oldRelativePath);

    if (broadcast) {
      WebsocketSyncService.instance.broadcastMoveNode('User_${Platform.localHostname}', oldRelativePath, targetParentRelativePath);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
