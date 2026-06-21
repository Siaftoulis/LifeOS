import 'dart:io';
import 'dart:async';
import 'database/database.dart';
import 'database/dao.dart';
import 'core/obsidian/frontmatter_service.dart';

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
      final fm = FrontmatterService.parseFrontmatter(content);
      
      if (fm.isEmpty) return;
      
      if (fm.containsKey('id')) {
        final String id = fm['id'].toString().trim();
        final int updatedAt = fm.containsKey('updated_at') ? int.parse(fm['updated_at'].toString()) : 0;
        
        // Push metadata changes to local cache
        await dao.insertOrUpdate(LifeEntitiesCompanion.insert(
          id: id,
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
