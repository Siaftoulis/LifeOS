import 'dart:io';
import 'dart:async';
import 'database/database.dart';
import 'database/dao.dart';

class VaultWatcher {
  final String vaultPath;
  final LifeEntitiesDao dao;
  
  VaultWatcher(this.vaultPath, this.dao);

  void startWatching() {
    final dir = Directory(vaultPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    
    // Native API wrapping Win32 ReadDirectoryChangesW / Android inotify
    dir.watch(events: FileSystemEvent.modify).listen((event) {
      if (event.path.endsWith('.md')) _processFile(File(event.path));
    });
  }

  Future<void> _processFile(File file) async {
    try {
      final content = await file.readAsString();
      final regex = RegExp(r'^---\n(.*?)\n---', multiLine: true, dotAll: true);
      final match = regex.firstMatch(content);
      if (match == null) return;
      
      final fm = match.group(1)!;
      final idMatch = RegExp(r'id:\s*(.+)').firstMatch(fm);
      final updateMatch = RegExp(r'updated_at:\s*(\d+)').firstMatch(fm);
      final syncMatch = RegExp(r'synced_at:\s*(\d+)').firstMatch(fm);
      
      if (idMatch != null) {
        final updatedAt = updateMatch != null ? int.parse(updateMatch.group(1)!) : 0;
        final syncedAt = syncMatch != null ? int.parse(syncMatch.group(1)!) : null;
        
        // Push metadata changes to local cache
        await dao.insertOrUpdate(LifeEntitiesCompanion.insert(
          id: idMatch.group(1)!.trim(),
          title: file.uri.pathSegments.last.replaceAll('.md', ''),
          createdAt: updatedAt,
          updatedAt: updatedAt,
        ));
      }
    } catch (e) {
      print('Watcher Error: $e');
    }
  }
}
