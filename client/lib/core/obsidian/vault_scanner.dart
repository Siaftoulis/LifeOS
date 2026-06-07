import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

class VaultNode {
  final String path;
  final String name;
  final bool isDirectory;
  final DateTime modified;
  
  VaultNode({
    required this.path, 
    required this.name, 
    required this.isDirectory, 
    required this.modified,
  });
}

class LinkGraph {
  final Map<String, List<String>> links = {};
  final Map<String, List<String>> backlinks = {};

  void addLink(String source, String target) {
    links.putIfAbsent(source, () => []).add(target);
    backlinks.putIfAbsent(target, () => []).add(source);
  }
}

class VaultScanner extends ChangeNotifier {
  final String vaultPath;
  StreamSubscription<FileSystemEvent>? _watchSubscription;
  
  Map<String, VaultNode> nodes = {};
  LinkGraph graph = LinkGraph();

  VaultScanner(this.vaultPath) {
    _initScanner();
  }

  Future<void> _initScanner() async {
    final dir = Directory(vaultPath);
    if (!await dir.exists()) return;
    
    await _scanDirectory(dir);
    
    _watchSubscription = dir.watch(recursive: true).listen((event) {
      _handleFileEvent(event);
    });
  }
  
  Future<void> _scanDirectory(Directory dir) async {
    try {
      final entities = dir.listSync(recursive: true);
      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.md')) {
          await _processFile(entity);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error scanning vault directory: $e');
    }
  }

  Future<void> _processFile(File file) async {
    try {
      final stat = await file.stat();
      nodes[file.path] = VaultNode(
        path: file.path,
        name: file.uri.pathSegments.last,
        isDirectory: false,
        modified: stat.modified,
      );
      
      final content = await file.readAsString();
      _parseContent(file.path, content);
    } catch (e) {
      debugPrint('Error processing file ${file.path}: $e');
    }
  }

  void _parseContent(String filePath, String content) {
    final wikiLinkExp = RegExp(r'\[\[(.*?)\]\]');
    
    graph.links[filePath]?.forEach((target) {
      graph.backlinks[target]?.remove(filePath);
    });
    graph.links[filePath] = [];
    
    for (final match in wikiLinkExp.allMatches(content)) {
      final linkTarget = match.group(1);
      if (linkTarget != null) {
        final resolvedTarget = _resolveShortestPath(linkTarget);
        if (resolvedTarget != null) {
          graph.addLink(filePath, resolvedTarget);
        }
      }
    }
  }

  String? _resolveShortestPath(String targetName) {
    final targetNameWithExt = targetName.endsWith('.md') ? targetName : '$targetName.md';
    for (final path in nodes.keys) {
      if (path.endsWith(targetNameWithExt)) {
        return path;
      }
    }
    return null;
  }
  
  Future<void> _handleFileEvent(FileSystemEvent event) async {
    if (event is FileSystemModifyEvent || event is FileSystemCreateEvent) {
       final file = File(event.path);
       if (await file.exists() && event.path.endsWith('.md')) {
         await _processFile(file);
         notifyListeners();
       }
    } else if (event is FileSystemDeleteEvent) {
       nodes.remove(event.path);
       notifyListeners();
    }
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    super.dispose();
  }
}
