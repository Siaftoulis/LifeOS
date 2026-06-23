import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../core/obsidian/config_parser.dart';
import '../../core/obsidian/vault_scanner.dart';
import '../../core/p2p_transfer_service.dart';
import '../../core/p2p_models.dart';
import '../../theme/everforest_colors.dart';

class MarkdownEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    List<TextSpan> spans = [];
    final text = this.text;
    
    final RegExp syntaxExp = RegExp(r'(\*\*.*?\*\*)|(# .*)');
    int lastMatchEnd = 0;
    
    for (final match in syntaxExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: style));
      }
      spans.add(TextSpan(
        text: match.group(0), 
        style: style?.copyWith(
          color: EverforestColors.green,
          fontWeight: FontWeight.bold,
        ),
      ));
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }
    
    return TextSpan(children: spans, style: style);
  }
}

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

class ZenWorkspace extends StatefulWidget {
  const ZenWorkspace({super.key});
  @override 
  State<ZenWorkspace> createState() => _ZenWorkspaceState();
}

class _ZenWorkspaceState extends State<ZenWorkspace> {
  final MarkdownEditingController _noteCtr = MarkdownEditingController();
  Timer? _debounce;
  ObsidianConfig? _config;
  VaultScanner? _vaultScanner;

  bool _leftSidebarOpen = true;
  bool _rightSidebarOpen = false;

  bool _isLeftSidebarPinned = true;
  bool _isSplitPane = false;

  final List<String> _openFilePaths = [];
  String? _activeFilePath;
  String? _selectedNodePath;
  List<FileNode> _fileTree = [];
  final Set<String> _expandedFolderPaths = {};

  final Color _accentColor = const Color(0xFF7E57C2);

  @override
  void initState() {
    super.initState();
    _noteCtr.addListener(_onNoteCursorChanged);
    _vaultScanner = VaultScanner('vault');
    _vaultScanner?.addListener(_onScannerUpdate);
    _refreshFileTree();
    _loadConfig();
    _loadInitialNote();
  }

  void _onNoteCursorChanged() {
    if (_activeFilePath != null) {
      final offset = _noteCtr.selection.baseOffset;
      if (offset >= 0) {
        final relativePath = _activeFilePath!.replaceAll('vault/', '').replaceAll('vault\\', '');
        P2PTransferService.instance.broadcastCursor(
          'User_${Platform.localHostname}',
          offset.toDouble(),
          0.0,
          relativePath,
        );
      }
    }
  }

  void _onScannerUpdate() {
    if (mounted) {
      _refreshFileTree();
    }
  }

  void _refreshFileTree() {
    setState(() {
      _fileTree = _buildFileTree();
    });
  }

  List<FileNode> _buildFileTree() {
    final rootDir = Directory('vault');
    if (!rootDir.existsSync()) {
      rootDir.createSync(recursive: true);
    }
    return _scanDir(rootDir);
  }

  List<FileNode> _scanDir(Directory dir) {
    final List<FileNode> nodes = [];
    try {
      final entities = dir.listSync();
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

        if (entity is Directory) {
          nodes.add(FileNode(
            name: name,
            path: entity.path,
            isDirectory: true,
            children: _scanDir(entity),
          ));
        } else if (entity is File && name.endsWith('.md')) {
          nodes.add(FileNode(
            name: name.replaceAll('.md', ''),
            path: entity.path,
            isDirectory: false,
            children: [],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error listing directory ${dir.path}: $e');
    }
    return nodes;
  }

  String _getTargetDirectory() {
    if (_selectedNodePath == null) return 'vault';
    final isDir = Directory(_selectedNodePath!).existsSync();
    if (isDir) return _selectedNodePath!;
    final file = File(_selectedNodePath!);
    return file.parent.path;
  }

  String _generateUuid() {
    final random = Random();
    final parts = List.generate(4, (_) => random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0'));
    return parts.join('-');
  }

  void _createNewFile(String name) {
    final parentDir = _getTargetDirectory();
    final sanitizedName = name.endsWith('.md') ? name : '$name.md';
    final filePath = '$parentDir/$sanitizedName';

    final file = File(filePath);
    if (file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File already exists: $name')),
      );
      return;
    }

    final uuid = _generateUuid();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final content = '''---
id: "$uuid"
updated_at: $timestamp
synced_at: null
---
# $name

''';

    try {
      file.writeAsStringSync(content);
      final relativePath = filePath.replaceAll('vault/', '').replaceAll('vault\\', '');
      ApiClient.instance.postDaemon('/api/markdown/sync', {
        'file_path': relativePath,
        'content': content,
      }).catchError((_) {});

      _refreshFileTree();
      _openFile(filePath);
    } catch (e) {
      debugPrint('Error creating file: $e');
    }
  }

  void _createNewFolder(String name) {
    final parentDir = _getTargetDirectory();
    final dirPath = '$parentDir/$name';

    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder already exists: $name')),
      );
      return;
    }

    try {
      dir.createSync(recursive: true);
      _refreshFileTree();
    } catch (e) {
      debugPrint('Error creating folder: $e');
    }
  }

  void _openFile(String filePath) {
    if (!_openFilePaths.contains(filePath)) {
      _openFilePaths.add(filePath);
    }
    _activeFilePath = filePath;

    try {
      final file = File(filePath);
      if (file.existsSync()) {
        _noteCtr.text = file.readAsStringSync();
      }
    } catch (e) {
      debugPrint('Error loading file $filePath: $e');
    }
  }

  void _closeTab(int index) {
    final filePath = _openFilePaths[index];
    _openFilePaths.removeAt(index);

    if (_activeFilePath == filePath) {
      if (_openFilePaths.isNotEmpty) {
        final newIndex = index.clamp(0, _openFilePaths.length - 1);
        _openFile(_openFilePaths[newIndex]);
      } else {
        _activeFilePath = null;
        _noteCtr.clear();
      }
    }
    _refreshFileTree();
  }

  void _saveCurrentNote() {
    if (_activeFilePath == null) return;
    final text = _noteCtr.text;

    try {
      File(_activeFilePath!).writeAsStringSync(text);
    } catch (e) {
      debugPrint('Error saving file locally: $e');
    }

    final relativePath = _activeFilePath!.replaceAll('vault/', '').replaceAll('vault\\', '');
    ApiClient.instance.postDaemon('/api/markdown/sync', {
      'file_path': relativePath,
      'content': text,
    }).catchError((e) {
      debugPrint('Daemon sync failed: $e');
    });
  }

  void _openOrCreateDailyNote() {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final dailyDir = Directory('vault/Daily');
    if (!dailyDir.existsSync()) {
      dailyDir.createSync(recursive: true);
    }

    final filePath = 'vault/Daily/$dateStr.md';
    final file = File(filePath);
    if (!file.existsSync()) {
      final uuid = _generateUuid();
      final timestamp = now.millisecondsSinceEpoch;
      final content = '''---
id: "$uuid"
updated_at: $timestamp
synced_at: null
---
# Daily Note: $dateStr

''';
      try {
        file.writeAsStringSync(content);
        final relativePath = 'Daily/$dateStr.md';
        ApiClient.instance.postDaemon('/api/markdown/sync', {
          'file_path': relativePath,
          'content': content,
        }).catchError((_) {});
      } catch (e) {
        debugPrint('Error creating daily note: $e');
      }
    }

    _refreshFileTree();
    _openFile(filePath);
  }

  void _insertLink(String noteName) {
    final text = _noteCtr.text;
    final selection = _noteCtr.selection;
    final linkText = '[[$noteName]]';

    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, linkText);
      _noteCtr.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + linkText.length),
      );
    } else {
      _noteCtr.text = '$text$linkText';
    }
    _saveCurrentNote();
  }

  List<FileNode> _getAllNotes() {
    final List<FileNode> notes = [];
    void traverse(List<FileNode> list) {
      for (final node in list) {
        if (node.isDirectory) {
          traverse(node.children);
        } else {
          notes.add(node);
        }
      }
    }
    traverse(_fileTree);
    return notes;
  }

  void _showNewFolderDialog() {
    final targetDir = _getTargetDirectory();
    final relativeTarget = targetDir.replaceAll('vault/', '').replaceAll('vault\\', '');
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EverforestColors.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: const [
              Icon(Icons.create_new_folder, color: EverforestColors.blue),
              SizedBox(width: 8),
              Text('New Folder', style: TextStyle(color: EverforestColors.fg)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creating in: ${relativeTarget.isEmpty ? "Vault Root" : relativeTarget}',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: EverforestColors.fg),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Folder name',
                  hintStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.blue),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _createNewFolder(name);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Create', style: TextStyle(color: EverforestColors.blue)),
            ),
          ],
        );
      },
    );
  }

  void _showNewFileDialog() {
    final targetDir = _getTargetDirectory();
    final relativeTarget = targetDir.replaceAll('vault/', '').replaceAll('vault\\', '');
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EverforestColors.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Row(
            children: const [
              Icon(Icons.post_add, color: EverforestColors.green),
              SizedBox(width: 8),
              Text('New Note', style: TextStyle(color: EverforestColors.fg)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Creating in: ${relativeTarget.isEmpty ? "Vault Root" : relativeTarget}',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: EverforestColors.fg),
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Note title',
                  hintStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.green),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  _createNewFile(name);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Create', style: TextStyle(color: EverforestColors.green)),
            ),
          ],
        );
      },
    );
  }

  void _showInsertLinkDialog() {
    final notes = _getAllNotes();
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final query = controller.text.toLowerCase();
            final filtered = notes.where((note) => note.name.toLowerCase().contains(query)).toList();

            return AlertDialog(
              backgroundColor: EverforestColors.bg1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('Insert Link to Note', style: TextStyle(color: EverforestColors.fg)),
              content: SizedBox(
                width: 400,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: EverforestColors.fg),
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search notes...',
                        hintStyle: TextStyle(color: EverforestColors.grey),
                        prefixIcon: Icon(Icons.search, color: EverforestColors.grey),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: EverforestColors.bg2),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: EverforestColors.green),
                        ),
                      ),
                      onChanged: (val) {
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text('No notes found', style: TextStyle(color: EverforestColors.grey)),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final note = filtered[index];
                                return ListTile(
                                  title: Text(note.name, style: const TextStyle(color: EverforestColors.fg)),
                                  leading: const Icon(Icons.description_outlined, color: EverforestColors.grey),
                                  onTap: () {
                                    _insertLink(note.name);
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Future<void> _loadConfig() async {
    final parser = ConfigParser('vault');
    final cfg = await parser.parseConfig();
    if (mounted) setState(() => _config = cfg);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _noteCtr.removeListener(_onNoteCursorChanged);
    _noteCtr.dispose();
    _vaultScanner?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialNote() async {
    final List<String> paths = [];
    void collect(List<FileNode> nodes) {
      for (final n in nodes) {
        if (n.isDirectory) {
          collect(n.children);
        } else {
          paths.add(n.path);
        }
      }
    }
    collect(_fileTree);
    if (paths.isNotEmpty) {
      _openFile(paths.first);
    } else {
      _createNewFile('Welcome to LifeOS Zen Editor');
    }
  }
  
  void _showSettingsModal(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      showDialog(
        context: context,
        useSafeArea: false,
        builder: (context) {
          return const MobileSettingsDialog();
        }
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: EverforestColors.bg1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SizedBox(
            width: 800,
            height: 600,
            child: Row(
              children: [
                Container(
                  width: 200,
                  decoration: const BoxDecoration(
                    color: EverforestColors.bg2,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Options', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      _buildSettingsNavItem('Mobile', false),
                      _buildSettingsNavItem('Editor', false),
                      _buildSettingsNavItem('Files & Links', false),
                      _buildSettingsNavItem('Appearance', true),
                      _buildSettingsNavItem('Hotkeys', false),
                      _buildSettingsNavItem('About', false),
                      const Divider(color: EverforestColors.bg0),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Core plugins', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      _buildSettingsNavItem('Backlinks', false),
                      _buildSettingsNavItem('Command palette', false),
                      _buildSettingsNavItem('Daily notes', false),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Appearance', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.close, color: EverforestColors.grey), 
                              onPressed: () => Navigator.of(context).pop(),
                              splashRadius: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Base color scheme', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                Text('Choose Obsidian\'s default color scheme.', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Dark  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: EverforestColors.bg2),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Accent color', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                Text('Choose the accent color used throughout the app.', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.refresh, color: EverforestColors.grey, size: 20),
                                const SizedBox(width: 16),
                                Container(width: 32, height: 32, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: EverforestColors.bg2),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Themes', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                Text('Manage installed themes and browse community themes.', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Default  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 14)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsNavItem(String title, bool isActive) {
    return Material(
      color: isActive ? _accentColor.withValues(alpha: 0.2) : Colors.transparent,
      child: ListTile(
        title: Text(title, style: TextStyle(color: isActive ? _accentColor : EverforestColors.fg, fontSize: 14)),
        dense: true,
        hoverColor: Colors.white10,
        onTap: () {},
      ),
    );
  }

  Widget _buildHoverIconButton(IconData icon, String tooltip, VoidCallback onPressed, {Color? color}) {
    return IconButton(
      icon: Icon(icon, color: color ?? EverforestColors.grey), 
      tooltip: tooltip, 
      onPressed: onPressed,
      hoverColor: Colors.white10,
      splashRadius: 20,
    );
  }

  Widget _buildRibbon() {
    return Container(
      width: 48,
      color: EverforestColors.bg1,
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHoverIconButton(Icons.hub, 'Open Graph', () {}),
          _buildHoverIconButton(Icons.today, 'Daily Note', () => _openOrCreateDailyNote()),
          _buildHoverIconButton(Icons.folder_shared, 'Switch Vault', () {}),
          const Spacer(),
          _buildHoverIconButton(Icons.settings, 'Settings', () => _showSettingsModal(context)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMobileRibbon() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: EverforestColors.bg1,
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [
          _buildHoverIconButton(Icons.hub, 'Open Graph', () {}),
          _buildHoverIconButton(Icons.today, 'Daily Note', () => _openOrCreateDailyNote()),
          _buildHoverIconButton(Icons.folder_shared, 'Switch Vault', () {}),
          _buildHoverIconButton(Icons.settings, 'Settings', () => _showSettingsModal(context)),
        ],
      ),
    );
  }
  
  Widget _buildLeftSidebar() {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: EverforestColors.bg1, 
        border: Border(right: BorderSide(color: EverforestColors.bg2, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text('Notes', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: EverforestColors.grey, size: 20),
                  ],
                ),
                _buildHoverIconButton(
                  _isLeftSidebarPinned ? Icons.push_pin : Icons.push_pin_outlined, 
                  'Toggle Pin', 
                  () => setState(() {
                    _isLeftSidebarPinned = !_isLeftSidebarPinned;
                    if (!_isLeftSidebarPinned) _leftSidebarOpen = false;
                  }),
                  color: _isLeftSidebarPinned ? _accentColor : EverforestColors.grey,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.folder_open, color: EverforestColors.grey, size: 18),
                    SizedBox(width: 8),
                    Text('Files', style: TextStyle(color: EverforestColors.fg, fontSize: 14)),
                  ],
                ),
                Row(
                  children: [
                    _buildHoverIconButton(Icons.create_new_folder, 'New Folder', () => _showNewFolderDialog()),
                    _buildHoverIconButton(Icons.post_add, 'New File', () => _showNewFileDialog()),
                    _buildHoverIconButton(Icons.link, 'Insert Link', () => _showInsertLinkDialog()),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: _buildFileTreeWidget(_fileTree),
            ),
          ),
          const Divider(color: EverforestColors.bg2),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.people, color: EverforestColors.green, size: 16),
                    SizedBox(width: 8),
                    Text('LAN Co-editors', style: TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<Map<String, RemoteCursor>>(
                  valueListenable: P2PTransferService.instance.cursorsNotifier,
                  builder: (context, cursors, _) {
                    if (cursors.isEmpty) {
                      return const Text('No active co-editors', style: TextStyle(color: EverforestColors.grey, fontSize: 11));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: cursors.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: EverforestColors.green),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${entry.key} editing ${entry.value.filePath}',
                                  style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTreeWidget(List<FileNode> nodes, {double depth = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: nodes.map((node) {
        if (node.isDirectory) {
          final isExpanded = _expandedFolderPaths.contains(node.path);
          final isSelected = _selectedNodePath == node.path;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTreeRow(
                title: node.name,
                path: node.path,
                isFolder: true,
                isExpanded: isExpanded,
                isSelected: isSelected,
                depth: depth,
                onTap: () {
                  setState(() {
                    _selectedNodePath = node.path;
                    if (isExpanded) {
                      _expandedFolderPaths.remove(node.path);
                    } else {
                      _expandedFolderPaths.add(node.path);
                    }
                  });
                },
              ),
              if (isExpanded)
                _buildFileTreeWidget(node.children, depth: depth + 12),
            ],
          );
        } else {
          final isSelected = _selectedNodePath == node.path;
          return _buildTreeRow(
            title: node.name,
            path: node.path,
            isFolder: false,
            isExpanded: false,
            isSelected: isSelected,
            depth: depth,
            onTap: () {
              setState(() {
                _selectedNodePath = node.path;
                _openFile(node.path);
              });
            },
          );
        }
      }).toList(),
    );
  }

  Widget _buildTreeRow({
    required String title,
    required String path,
    required bool isFolder,
    required bool isExpanded,
    required bool isSelected,
    required double depth,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? EverforestColors.bg2 : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.white10,
        child: Padding(
          padding: EdgeInsets.only(left: depth + 8.0, top: 6, bottom: 6, right: 8),
          child: Row(
            children: [
              Icon(
                isFolder
                    ? (isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right)
                    : Icons.description_outlined,
                color: isSelected ? EverforestColors.green : EverforestColors.grey,
                size: 16,
              ),
              const SizedBox(width: 6),
              if (isFolder)
                const Icon(Icons.folder, color: EverforestColors.blue, size: 14)
              else
                const SizedBox.shrink(),
              if (isFolder) const SizedBox(width: 4) else const SizedBox.shrink(),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? EverforestColors.green : EverforestColors.fg,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRightSidebar({bool isMobile = false}) {
    final List<String> backlinks = [];
    if (_activeFilePath != null && _vaultScanner != null) {
      final targetKey = _activeFilePath!;
      final incoming = _vaultScanner!.graph.backlinks[targetKey];
      if (incoming != null) {
        for (final src in incoming) {
          backlinks.add(src);
        }
      }
    }

    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BACKLINKS', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              if (!isMobile)
                _buildHoverIconButton(Icons.close, 'Close', () => setState(() => _rightSidebarOpen = false)),
            ],
          ),
        ),
        if (backlinks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No incoming links', style: TextStyle(color: EverforestColors.grey, fontSize: 13, fontStyle: FontStyle.italic)),
          )
        else
          ...backlinks.map((path) {
            final name = path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
            return Material(
              type: MaterialType.transparency,
              child: ListTile(
                title: Text(name, style: const TextStyle(color: EverforestColors.fg, fontSize: 13)),
                leading: const Icon(Icons.link, color: EverforestColors.grey, size: 16),
                dense: true,
                hoverColor: Colors.white10,
                onTap: () {
                  setState(() {
                    _selectedNodePath = path;
                    _openFile(path);
                  });
                },
              ),
            );
          }).toList(),
      ],
    );

    if (isMobile) {
      return Container(
        color: EverforestColors.bg1,
        child: content,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _rightSidebarOpen ? 260 : 0,
      color: EverforestColors.bg1,
      child: _rightSidebarOpen ? content : const SizedBox.shrink(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 40,
      color: EverforestColors.bg0,
      child: Row(
        children: [
          if (!_isLeftSidebarPinned)
            _buildHoverIconButton(Icons.menu, 'Menu', () => setState(() => _leftSidebarOpen = !_leftSidebarOpen)),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _openFilePaths.length,
              itemBuilder: (context, index) {
                final path = _openFilePaths[index];
                bool isActive = _activeFilePath == path;
                final fileName = path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
                return GestureDetector(
                  onTap: () => setState(() => _openFile(path)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive ? EverforestColors.bg0 : EverforestColors.bg1,
                      border: Border(
                        top: BorderSide(color: isActive ? _accentColor : Colors.transparent, width: 2),
                        right: const BorderSide(color: EverforestColors.bg2, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: isActive ? _accentColor : EverforestColors.grey, size: 14),
                        const SizedBox(width: 8),
                        Text(fileName, style: TextStyle(color: isActive ? EverforestColors.fg : EverforestColors.grey, fontSize: 13)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, size: 14, color: EverforestColors.grey),
                          onPressed: () => setState(() => _closeTab(index)),
                          splashRadius: 16,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildHoverIconButton(Icons.add, 'New tab', () => _showNewFileDialog()),
          _buildHoverIconButton(Icons.keyboard_arrow_down, 'More tabs', () {
            if (_openFilePaths.isEmpty) return;
            final RenderBox button = context.findRenderObject() as RenderBox;
            final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
            final RelativeRect position = RelativeRect.fromRect(
              Rect.fromPoints(
                button.localToGlobal(Offset.zero, ancestor: overlay),
                button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
              ),
              Offset.zero & overlay.size,
            );
            
            showMenu(
              context: context,
              position: position,
              color: EverforestColors.bg1,
              items: _openFilePaths.map((path) {
                final name = path.split(RegExp(r'[/\\]')).last.replaceAll('.md', '');
                return PopupMenuItem(
                  value: path,
                  child: Text(name, style: const TextStyle(color: EverforestColors.fg)),
                );
              }).toList(),
            ).then((selectedPath) {
              if (selectedPath != null) {
                setState(() => _openFile(selectedPath));
              }
            });
          }),
          _buildHoverIconButton(Icons.vertical_split, 'Split Right', () => setState(() => _isSplitPane = !_isSplitPane)),
          _buildHoverIconButton(Icons.menu_open, 'Toggle Backlinks', () => setState(() => _rightSidebarOpen = !_rightSidebarOpen)),
        ],
      ),
    );
  }

  Widget _buildSplitPane() {
    return Container(
      width: 450,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: EverforestColors.bg2, width: 1)),
        color: EverforestColors.bg0,
      ),
      child: Column(
        children: [
          Container(
            height: 40,
            color: EverforestColors.bg0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      border: Border(
                        top: BorderSide(color: _accentColor, width: 2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: _accentColor, size: 14),
                        const SizedBox(width: 8),
                        const Text('Evergreen notes turn id...', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.close, size: 14, color: EverforestColors.grey), onPressed: () {}, splashRadius: 16, constraints: const BoxConstraints()),
                      ],
                    ),
                  ),
                ),
                _buildHoverIconButton(Icons.add, 'New tab', () {}),
                _buildHoverIconButton(Icons.close, 'Close pane', () => setState(() => _isSplitPane = false)),
              ],
            ),
          ),
          const Divider(height: 1, color: EverforestColors.bg2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                _buildHoverIconButton(Icons.arrow_back, 'Back', () {}),
                _buildHoverIconButton(Icons.arrow_forward, 'Forward', () {}),
                const Spacer(),
                const Text('Ideas / Writing is telepathy', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
                const Spacer(),
                _buildHoverIconButton(Icons.edit, 'Edit', () {}, color: _accentColor),
                _buildHoverIconButton(Icons.more_vert, 'More options', () {}),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Evergreen notes turn ideas into objects that you can manipulate', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                        child: Text('#evergreen', style: TextStyle(color: _accentColor, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Evergreen notes allow you to think about complex ideas by building them up from smaller composable ideas.', style: TextStyle(color: EverforestColors.fg, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCentralGrid({required bool isMobile}) {
    return Expanded(
      child: Container(
        color: EverforestColors.bg0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isMobile) _buildTabBar(),
            const Divider(height: 1, color: EverforestColors.bg2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  _buildHoverIconButton(Icons.arrow_back, 'Back', () {}),
                  _buildHoverIconButton(Icons.arrow_forward, 'Forward', () {}),
                  const Expanded(
                    child: Text('Ideas / Writing is telepathy', style: TextStyle(color: EverforestColors.grey, fontSize: 12), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                  ),
                  _buildHoverIconButton(Icons.menu_book, 'Reading view', () {}, color: _accentColor),
                  _buildHoverIconButton(Icons.more_vert, 'More options', () {}),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_config?.showLineNumber == true)
                      Container(
                        width: 40,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 16, top: 12),
                        child: Text(
                          List.generate('\n'.allMatches(_noteCtr.text).length + 1, (i) => '${i + 1}').join('\n'),
                          style: const TextStyle(color: EverforestColors.grey, fontFamily: 'JetBrainsMono', fontSize: 14),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _noteCtr,
                        enabled: _activeFilePath != null,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(color: EverforestColors.fg, fontFamily: 'JetBrainsMono', fontSize: 16, height: 1.6),
                        decoration: InputDecoration(
                          hintText: _activeFilePath != null ? 'Start typing...' : 'No open file. Select or create a note.', 
                          hintStyle: const TextStyle(color: EverforestColors.grey), 
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.only(top: 12),
                        ),
                        onChanged: (text) {
                          if (_config?.showLineNumber == true) {
                            setState(() {}); 
                          }
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 800), () {
                            _saveCurrentNote();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileActionBar(BuildContext context) {
    return Container(
      color: EverforestColors.bg1,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: EverforestColors.fg),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const Expanded(
                child: Text(
                  'workspace.md', 
                  style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu_open, color: EverforestColors.fg),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override 
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 768;

        if (isMobile) {
          return Scaffold(
            backgroundColor: EverforestColors.bg0,
            drawer: Drawer(
              width: constraints.maxWidth * 0.8,
              backgroundColor: EverforestColors.bg1,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMobileRibbon(),
                    const Divider(height: 1, color: EverforestColors.bg1),
                    Expanded(child: _buildLeftSidebar()),
                  ],
                ),
              ),
            ),
            endDrawer: Drawer(
              width: constraints.maxWidth * 0.8,
              backgroundColor: EverforestColors.bg1,
              child: SafeArea(
                child: _buildRightSidebar(isMobile: true),
              ),
            ),
            body: Builder(
              builder: (innerContext) {
                return Column(
                  children: [
                    _buildMobileActionBar(innerContext),
                    const Divider(height: 1, color: EverforestColors.bg2),
                    _buildCentralGrid(isMobile: true),
                  ],
                );
              }
            ),
          );
        }

        // Desktop/Tablet Layout
        return Scaffold(
          backgroundColor: EverforestColors.bg0,
          body: Stack(
            children: [
              Row(
                children: [
                  _buildRibbon(),
                  if (_isLeftSidebarPinned && _leftSidebarOpen) _buildLeftSidebar(),
                  _buildCentralGrid(isMobile: false),
                  if (_isSplitPane) _buildSplitPane(),
                  _buildRightSidebar(),
                ],
              ),
              if (!_isLeftSidebarPinned && _leftSidebarOpen)
                Positioned.fill(
                  left: 48,
                  child: Row(
                    children: [
                      _buildLeftSidebar(),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _leftSidebarOpen = false),
                          child: Container(color: Colors.black45),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class MobileSettingsDialog extends StatefulWidget {
  const MobileSettingsDialog({super.key});
  @override
  State<MobileSettingsDialog> createState() => _MobileSettingsDialogState();
}

class _MobileSettingsDialogState extends State<MobileSettingsDialog> {
  String? _activeCategory;

  Widget _buildCategoryList() {
    return Scaffold(
      backgroundColor: EverforestColors.bg1,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: EverforestColors.grey),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Settings', style: TextStyle(color: EverforestColors.fg, fontSize: 18)),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Options', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          _buildNavItem('Mobile'),
          _buildNavItem('Editor'),
          _buildNavItem('Files & Links'),
          _buildNavItem('Appearance'),
          _buildNavItem('Hotkeys'),
          _buildNavItem('About'),
          const Divider(color: EverforestColors.bg0),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Core plugins', style: TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          _buildNavItem('Backlinks'),
          _buildNavItem('Command palette'),
          _buildNavItem('Daily notes'),
        ],
      ),
    );
  }

  Widget _buildNavItem(String title) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        title: Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: EverforestColors.grey),
        onTap: () {
          setState(() {
            _activeCategory = title;
          });
        },
      ),
    );
  }

  Widget _buildAppearanceCategory() {
    final _accentColor = const Color(0xFF7E57C2);
    return Scaffold(
      backgroundColor: EverforestColors.bg1,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: EverforestColors.grey),
          onPressed: () {
            setState(() {
              _activeCategory = null;
            });
          },
        ),
        title: const Text('Appearance', style: TextStyle(color: EverforestColors.fg, fontSize: 18)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Base color scheme', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const Text('Choose Obsidian\'s default color scheme.', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
            child: const Text('Dark  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          ),
          const SizedBox(height: 24),
          const Divider(color: EverforestColors.bg2),
          const SizedBox(height: 24),
          const Text('Accent color', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const Text('Choose the accent color used throughout the app.', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.refresh, color: EverforestColors.grey, size: 24),
              const SizedBox(width: 16),
              Container(width: 40, height: 40, decoration: BoxDecoration(color: _accentColor, shape: BoxShape.circle)),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: EverforestColors.bg2),
          const SizedBox(height: 24),
          const Text('Themes', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const Text('Manage installed themes and browse community themes.', style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(4)),
                  child: const Text('Default  ▼', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: _accentColor, borderRadius: BorderRadius.circular(4)),
                child: const Text('Manage', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeCategory == 'Appearance') {
      return _buildAppearanceCategory();
    }
    if (_activeCategory != null) {
      return Scaffold(
        backgroundColor: EverforestColors.bg1,
        appBar: AppBar(
          backgroundColor: EverforestColors.bg1,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: EverforestColors.grey),
            onPressed: () => setState(() => _activeCategory = null),
          ),
          title: Text(_activeCategory!, style: const TextStyle(color: EverforestColors.fg, fontSize: 18)),
        ),
        body: const Center(child: Text('Under Construction', style: TextStyle(color: EverforestColors.grey))),
      );
    }
    return _buildCategoryList();
  }
}
