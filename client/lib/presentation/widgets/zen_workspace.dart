import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/command/copy_paste_extension.dart';

import '../../appflowy/src/editor/block_component/callout_block_component/callout_block_component.dart';
import '../../appflowy/src/editor/block_component/code_block_component/code_block_component.dart';
import '../../appflowy/src/editor/block_component/toggle_block_component/toggle_block_component.dart';
import '../../appflowy/src/editor/selection_menu/selection_menu_service.dart';
import '../../appflowy/src/editor/wiki_link_shortcut.dart';
import '../../auth_service.dart';
import '../../api_client.dart';
import '../../core/obsidian/zen_collab_service.dart';
import '../../core/obsidian/zen_collab_transport.dart';
import '../../core/obsidian/zen_file_system.dart';
import '../../core/obsidian/zen_sync_service.dart';
import '../../core/zen_cloud_service.dart';
import '../../theme/everforest_colors.dart';
import '../../database/preferences_service.dart';
import '../theme/zen_markdown_bridge.dart';
import '../../plugins/markdown/markdown_storage.dart';
import '../../plugins/markdown/zen_embed_block.dart';
import 'zen_sidebar.dart';
import 'zen_toolbar_items.dart';
import 'zen_workspace/shortcuts/zen_editor_shortcuts.dart';
import 'zen_workspace/overlays/remote_cursor_overlay.dart';
import 'zen_workspace/dialogs/vault_search_dialog.dart';

class ZenWorkspace extends StatefulWidget {
  const ZenWorkspace({super.key});

  @override
  State<ZenWorkspace> createState() => _ZenWorkspaceState();
}

class _ZenWorkspaceState extends State<ZenWorkspace> {
  EditorState? _editorState;
  EditorScrollController? _editorScrollController;
  final FocusNode _editorFocusNode = FocusNode(debugLabel: 'zen_appflowy_editor_focus');
  Timer? _debounce;

  bool _leftSidebarOpen = true;
  final List<String> _openFilePaths = [];
  String? _activeFilePath;
  List<FileNode> _fileTree = [];

  // Live collab per active file
  ZenCollabService? _collab;
  StreamSubscription? _collabSub;
  Timer? _cursorThrottle;
  final ValueNotifier<Map<String, RemotePresence>> _remotePresences =
      ValueNotifier({});

  String _vaultPath = 'vault';
  String _activeWorkspace = '';

  /// The vault lives on the real OS only where it must: web keeps it as a
  /// logical root on the server, desktop keeps the legacy relative 'vault/'
  /// folder, mobile uses the app documents dir (relative paths are read-only
  /// on Android/iOS and would silently fail).
  Future<String> _resolveVaultPath() async {
    if (kIsWeb) return 'vault';
    if (!Platform.isAndroid && !Platform.isIOS) return 'vault';
    try {
      return await MarkdownStorage.getRootPath();
    } catch (e) {
      debugPrint('ZenWorkspace: docs dir unavailable ($e), falling back to relative vault');
      return 'vault';
    }
  }

  static const _userColors = [
    '#E78284', '#8CAAEE', '#A6D189', '#E5C890', '#81C8BE', '#F4B8E4',
    '#EE99A0', '#B5BFE2',
  ];

  String get _collabRoom {
    if (_activeFilePath == null) return '';
    // Room = path relative to the vault root (same on every device), not the
    // absolute path, or desktop/mobile/web would each join a different room.
    final vault = _vaultPath.replaceAll('\\', '/');
    final p = _activeFilePath!.replaceAll('\\', '/');
    return p.startsWith('$vault/') ? p.substring(vault.length + 1) : p;
  }

  String get _workspacePath => _activeWorkspace.isEmpty
      ? _vaultPath
      : '$_vaultPath/workspaces/$_activeWorkspace';

  final GlobalKey _workspaceMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initWorkspace();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cursorThrottle?.cancel();
    _disposeCollab();
    _editorState?.dispose();
    _editorScrollController?.dispose();
    _editorFocusNode.dispose();
    _remotePresences.dispose();
    super.dispose();
  }

  Future<void> _initWorkspace() async {
    final fs = ZenFileSystem.instance;
    _vaultPath = await _resolveVaultPath();
    // Web: the cache must mirror the server BEFORE any local mutation, or a
    // create/rename would be applied over stale state and lose data.
    if (kIsWeb) await fs.ensureLoaded();
    fs.createDirectory(_vaultPath);
    _activeWorkspace = PreferencesService.zenWorkspace.value;
    if (_activeWorkspace.isNotEmpty) {
      fs.createDirectory('$_vaultPath/workspaces/$_activeWorkspace');
    }
    ZenLinkState.workspacePath = _workspacePath;
    // ponytail: sync/cloud engines are dart:io-only (drift + file watchers);
    // web keeps 100% server persistence via the server-backed ZenFileSystem.
    if (!kIsWeb) {
      await ZenSyncService.instance.initialize(_vaultPath);
      ZenCloudService.instance.start();
    }
    _refreshFileTree();
    _loadInitialDocument();
  }

  void _refreshFileTree() {
    setState(() {
      _fileTree = _visibleTree(ZenFileSystem.instance.scanDirectory(_workspacePath));
    });
  }

  /// Filters raw scans down to what the sidebar shows: .md/.json files with
  /// the extension stripped, dotfolders hidden, and the 'workspaces' folder
  /// hidden when browsing the bare vault root.
  List<FileNode> _visibleTree(List<FileNode> nodes) {
    final out = <FileNode>[];
    for (final n in nodes) {
      if (n.isDirectory) {
        if (n.name == 'workspaces' && _activeWorkspace.isEmpty) continue;
        out.add(FileNode(
          name: n.name,
          path: n.path,
          isDirectory: true,
          children: _visibleTree(n.children),
        ));
      } else if (n.name.endsWith('.md') || n.name.endsWith('.json')) {
        out.add(FileNode(
          name: n.name.replaceAll('.md', '').replaceAll('.json', ''),
          path: n.path,
          isDirectory: false,
          children: [],
        ));
      }
    }
    return out;
  }

  void _loadInitialDocument() {
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
      _createNewDocument('Welcome to Zen Editor');
    }
  }

  void _createNewDocument(String title, {String? parentFolderPath}) {
    final fs = ZenFileSystem.instance;
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final parentDir = parentFolderPath ?? _workspacePath;
    final baseFilePath = '$parentDir/$sanitizedTitle.json';

    String targetPath = baseFilePath;
    int counter = 1;
    while (fs.exists(targetPath)) {
      targetPath = '$parentDir/${sanitizedTitle}_$counter.json';
      counter++;
    }

    final initialDocument = Document(
      root: Node(
        type: PageBlockKeys.type,
        children: [
          Node(
            type: HeadingBlockKeys.type,
            attributes: {
              HeadingBlockKeys.level: 1,
              HeadingBlockKeys.delta: (Delta()..insert(title)).toJson(),
            },
          ),
          Node(
            type: ParagraphBlockKeys.type,
            attributes: {
              ParagraphBlockKeys.delta: (Delta()..insert('Start writing in AppFlowy Zen Editor...')).toJson(),
            },
          ),
        ],
      ),
    );

    fs.writeFile(targetPath, jsonEncode(initialDocument.toJson()));
    if (!kIsWeb) ZenSyncService.instance.upsertNodeFromDisk(targetPath);
    _refreshFileTree();
    _openFile(targetPath);
  }

  Future<String?> _promptTextDialog({
    required String title,
    required String hint,
    required String initial,
    required String actionLabel,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: Text(title, style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: EverforestColors.fg),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: EverforestColors.grey),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(actionLabel, style: const TextStyle(color: Color(0xFF1E2326), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return (result == null || result.isEmpty) ? null : result;
  }

  Future<void> _showCreateFileDialog({String? parentFolderPath}) async {
    final fileName = await _promptTextDialog(
      title: 'Create New Document',
      hint: 'Document Name',
      initial: 'Untitled Document',
      actionLabel: 'Create',
    );

    if (fileName != null) {
      _createNewDocument(fileName, parentFolderPath: parentFolderPath);
    }
  }

  Future<void> _showCreateFolderDialog({String? parentFolderPath}) async {
    final folderName = await _promptTextDialog(
      title: 'Create New Folder',
      hint: 'Folder Name',
      initial: 'New Folder',
      actionLabel: 'Create',
    );

    if (folderName != null) {
      final sanitized = folderName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final parentDir = parentFolderPath ?? _workspacePath;
      ZenFileSystem.instance.createDirectory('$parentDir/$sanitized');
      _refreshFileTree();
    }
  }

  Future<void> _showWorkspaceMenu() async {
    final renderBox = _workspaceMenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final workspaceNames = ['', ...ZenFileSystem.instance.listWorkspaces(_vaultPath)];

    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        renderBox.localToGlobal(Offset.zero) & renderBox.size,
        overlay != null ? Offset.zero & overlay.size : Offset.zero & MediaQuery.of(context).size,
      ),
      color: const Color(0xFF242B2E),
      items: [
        for (final name in workspaceNames)
          PopupMenuItem<String>(
            value: name,
            height: 36,
            child: Row(
              children: [
                Icon(
                  _activeWorkspace == name ? Icons.check : Icons.dashboard_outlined,
                  size: 16,
                  color: _activeWorkspace == name ? EverforestColors.green : EverforestColors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  name.isEmpty ? 'Zen' : name,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__new__',
          height: 36,
          child: Row(
            children: [
              Icon(Icons.add, size: 16, color: EverforestColors.green),
              SizedBox(width: 8),
              Text('New Workspace', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
            ],
          ),
        ),
        if (_activeWorkspace.isNotEmpty) ...[
          const PopupMenuItem<String>(
            value: '__rename__',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: EverforestColors.grey),
                SizedBox(width: 8),
                Text('Rename Workspace', style: TextStyle(color: EverforestColors.fg, fontSize: 13)),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: '__delete__',
            height: 36,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 16, color: EverforestColors.red),
                SizedBox(width: 8),
                Text('Delete Workspace', style: TextStyle(color: EverforestColors.red, fontSize: 13)),
              ],
            ),
          ),
        ],
      ],
    );

    if (result == null || result == _activeWorkspace) return;
    if (result == '__new__') {
      final name = await _showCreateWorkspaceDialog();
      if (name != null) _switchWorkspace(name);
    } else if (result == '__rename__') {
      await _showRenameWorkspaceDialog();
    } else if (result == '__delete__') {
      await _deleteActiveWorkspace();
    } else {
      _switchWorkspace(result);
    }
  }

  Future<String?> _showCreateWorkspaceDialog() async {
    final name = await _promptTextDialog(
      title: 'Create New Workspace',
      hint: 'Workspace Name',
      initial: 'New Workspace',
      actionLabel: 'Create',
    );
    if (name == null) return null;
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> _showRenameWorkspaceDialog() async {
    final name = await _promptTextDialog(
      title: 'Rename Workspace',
      hint: 'Workspace Name',
      initial: _activeWorkspace,
      actionLabel: 'Rename',
    );
    final sanitized = name?.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (sanitized == null || sanitized.isEmpty || sanitized == _activeWorkspace) return;

    final fs = ZenFileSystem.instance;
    final newPath = '$_vaultPath/workspaces/$sanitized';
    if (fs.exists(newPath)) return;
    try {
      fs.rename('$_vaultPath/workspaces/$_activeWorkspace', newPath);
    } catch (e) {
      debugPrint('Workspace rename failed: $e');
      return;
    }
    _activeWorkspace = sanitized;
    PreferencesService.setZenWorkspace(sanitized);
    ZenLinkState.workspacePath = _workspacePath;
    _refreshFileTree();
  }

  Future<void> _deleteActiveWorkspace() async {
    final name = _activeWorkspace;
    if (name.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: Text('Delete workspace "$name"?',
            style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
        content: const Text(
          'All pages inside it will be permanently deleted. This cannot be undone.',
          style: TextStyle(color: EverforestColors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: EverforestColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    _switchWorkspace('');
    ZenFileSystem.instance.deleteWorkspace(_vaultPath, name);
    _refreshFileTree();
  }

  void _switchWorkspace(String name) {
    ZenFileSystem.instance
        .createDirectory(name.isEmpty ? _vaultPath : '$_vaultPath/workspaces/$name');
    _activeWorkspace = name;
    PreferencesService.setZenWorkspace(name);
    ZenLinkState.workspacePath = _workspacePath;

    _debounce?.cancel();
    _disposeCollab();
    _editorState?.dispose();
    _editorState = null;
    _editorScrollController?.dispose();
    _editorScrollController = null;
    _openFilePaths.clear();
    _activeFilePath = null;

    _refreshFileTree();
    _loadInitialDocument();
  }

  void _handleZenLink(String target) {
    final colon = target.indexOf(':');
    if (colon < 0) {
      if (zenEmbedSpecs.containsKey(target)) {
        _openModule(target);
      } else {
        _openLinkedPage(target);
      }
      return;
    }
    final type = target.substring(0, colon);
    final name = target.substring(colon + 1);
    if (type == 'page') {
      _openLinkedPage(name);
    } else if (zenEmbedSpecs.containsKey(type)) {
      _openModule(type);
    } else {
      _showLinkError('Unknown link type "$type"');
    }
  }

  void _openLinkedPage(String name) {
    FileNode? found;
    void search(List<FileNode> nodes) {
      for (final n in nodes) {
        if (found != null) return;
        if (!n.isDirectory && n.name.toLowerCase() == name.toLowerCase()) {
          found = n;
          return;
        }
        search(n.children);
      }
    }

    search(_fileTree);
    if (found != null) {
      _openFile(found!.path);
    } else {
      _showLinkError('Page "$name" not found');
    }
  }

  void _openModule(String type) {
    final spec = zenEmbedSpecs[type];
    if (spec == null) {
      _showLinkError('Unknown module "$type"');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => spec.full()));
  }

  void _showLinkError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: EverforestColors.fg)),
      backgroundColor: const Color(0xFF2E383C),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openFile(String filePath) {
    if (!_openFilePaths.contains(filePath)) {
      _openFilePaths.add(filePath);
    }
    _activeFilePath = filePath;

    try {
      final content = ZenFileSystem.instance.readFile(filePath);
      if (content != null) {
        try {
          if (content.trim().startsWith('{')) {
            final jsonMap = jsonDecode(content);
            _editorState = EditorState(document: Document.fromJson(jsonMap));
          } else {
            _editorState = ZenMarkdownBridge.createEditorState(content).editorState;
          }
        } catch (_) {
          _editorState = ZenMarkdownBridge.createEditorState(content).editorState;
        }
      } else {
        _editorState = EditorState.blank();
      }

      if (_editorState != null) {
        _sanitizeDocumentNodes(_editorState!.document.root);
      }

      _editorScrollController?.dispose();
      _editorScrollController = EditorScrollController(editorState: _editorState!, shrinkWrap: false);
      _editorState!.document.root.addListener(_onEditorContentChanged);

      _editorFocusNode.addListener(() {
        debugPrint('[ZenWorkspace] Focus changed: hasFocus = ${_editorFocusNode.hasFocus}');
        if (_editorFocusNode.hasFocus && _editorState != null) {
          final sel = _editorState!.selection;
          final nodes = sel != null ? _editorState!.getNodesInSelection(sel) : [];
          debugPrint('[ZenWorkspace] IME attach status on focus: selection=$sel, nodesInSelection=${nodes.length} (IME attached: ${nodes.isNotEmpty})');
        }
      });

      setState(() {});
      _setupCollab();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _editorState != null) {
          _editorFocusNode.requestFocus();
          final firstBlock = _editorState!.document.root.children.firstOrNull;
          if (firstBlock != null) {
            final selection = Selection.collapsed(
              Position(path: firstBlock.path, offset: 0),
            );
            _editorState!.selection = selection;
            final nodes = _editorState!.getNodesInSelection(selection);
            debugPrint('[ZenWorkspace] Initial selection set to path ${firstBlock.path}, nodes count: ${nodes.length} (IME ready: ${nodes.isNotEmpty})');
          }
        }
      });

    } catch (e) {
      debugPrint('Error loading file $filePath: $e');
    }
  }


  void _disposeCollab() {
    _cursorThrottle?.cancel();
    _cursorThrottle = null;
    _collabSub?.cancel();
    _collabSub = null;
    _collab?.dispose();
    _collab = null;
    ZenCollabTransport.instance.disconnect();
    _remotePresences.value = {};
  }

  /// Starts live collab for the currently open document: attaches the Yjs
  /// CRDT to the active editor state, joins the doc room on the Go daemon and
  /// relays remote presence (cursors) + crdt updates into the editor.
  void _setupCollab() {
    final state = _editorState;
    final room = _collabRoom;
    if (state == null || room.isEmpty) return;

    final user = AuthService.instance.currentUser.value;
    final userId = user?.username ??
        (kIsWeb ? 'web_user' : 'user_${Platform.localHostname}');
    final userName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : userId;
    final colorIndex = userId.hashCode.abs() % _userColors.length;

    _disposeCollab();
    final transport = ZenCollabTransport.instance;
    _collab = ZenCollabService(
      notePath: room,
      userId: userId,
      userName: userName,
      userColorHex: _userColors[colorIndex],
      sendMessage: transport.send,
      enableFlush: false, // workspace saves to disk itself
    )..attachToEditorState(state);

    _collabSub = transport.onMessage.listen((msg) {
      _collab?.handleRemoteMessage(msg);
    });

    transport.connect(room);

    // Local selection â†’ broadcast own cursor position (throttled).
    state.selectionNotifier.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    final state = _editorState;
    final collab = _collab;
    if (state == null || collab == null) return;
    _cursorThrottle?.cancel();
    _cursorThrottle = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _collab == null) return;
      _collab!.broadcastCursorSelection(state.selection);
    });
  }

  void _sanitizeDocumentNodes(Node node) {
    if (node.type == ParagraphBlockKeys.type ||
        node.type == HeadingBlockKeys.type ||
        node.type == TodoListBlockKeys.type ||
        node.type == BulletedListBlockKeys.type ||
        node.type == NumberedListBlockKeys.type ||
        node.type == QuoteBlockKeys.type) {
      if (node.attributes[ParagraphBlockKeys.delta] == null) {
        node.attributes[ParagraphBlockKeys.delta] = (Delta()..insert('')).toJson();
      }
    }
    for (final child in node.children) {
      _sanitizeDocumentNodes(child);
    }
  }




  void _onEditorContentChanged() {
    if (_activeFilePath == null || _editorState == null) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      try {
        final jsonMap = _editorState!.document.toJson();
        ZenFileSystem.instance.writeFile(_activeFilePath!, jsonEncode(jsonMap));
        if (!kIsWeb) ZenSyncService.instance.upsertNodeFromDisk(_activeFilePath!);
      } catch (e) {
        debugPrint('Error saving AppFlowy document: $e');
      }
    });
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
        _editorState = null;
      }
    }
    _refreshFileTree();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  String _extension(String path) {
    final n = _basename(path);
    final i = n.lastIndexOf('.');
    return i <= 0 ? '' : n.substring(i);
  }

  String _basenameNoExt(String path) {
    final n = _basename(path);
    final i = n.lastIndexOf('.');
    return i <= 0 ? n : n.substring(0, i);
  }

  Widget _buildSidebarContent() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF242B2E),
        border: Border(right: BorderSide(color: Color(0xFF2E383C), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    key: _workspaceMenuKey,
                    onTap: _showWorkspaceMenu,
                    child: Row(
                      children: [
                        const Icon(Icons.edit_note, color: EverforestColors.green, size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _activeWorkspace.isEmpty ? 'Zen' : _activeWorkspace,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down, color: EverforestColors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.note_add_outlined, color: EverforestColors.fg, size: 18),
                      tooltip: 'New Note',
                      onPressed: () => _showCreateFileDialog(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.create_new_folder_outlined, color: EverforestColors.fg, size: 18),
                      tooltip: 'New Folder',
                      onPressed: () => _showCreateFolderDialog(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFF2E383C)),
          Expanded(
            child: ZenSidebar(
              tree: _fileTree,
              activePath: _activeFilePath,
              onOpen: (path) {
                _openFile(path);
                if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                  Navigator.of(context).pop();
                }
              },
              onCreateFile: (parent) => _showCreateFileDialog(
                  parentFolderPath: parent.isEmpty ? null : parent),
              onCreateFolder: (parent) => _showCreateFolderDialog(
                  parentFolderPath: parent.isEmpty ? null : parent),
              onRename: _renameFile,
              onDuplicate: _duplicateFile,
              onDelete: _deleteFile,
              onMove: _moveFile,
              onChanged: () => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  void _showVaultSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _VaultSearchDialog(
        vaultPath: _vaultPath,
        onOpen: (path) {
          Navigator.of(context).pop();
          _openFile(path);
        },
      ),
    );
  }

  void _showExtractMarkdown() {
    final editorState = _editorState;
    if (editorState == null) return;
    final md = ZenMarkdownBridge.exportMarkdown(editorState, null);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.code, color: EverforestColors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              'Markdown preview',
              style: const TextStyle(color: EverforestColors.fg, fontSize: 15),
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          height: 360,
          child: SingleChildScrollView(
            child: SelectableText(
              md,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontFamily: 'JetBrains Mono',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: md));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Markdown copied to clipboard')),
              );
            },
            child: const Text('Copy', style: TextStyle(color: Color(0xFF1E2326), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleControls(double scale) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 14, color: EverforestColors.grey),
            tooltip: 'Zoom Out',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: scale > 0.75
                ? () => PreferencesService.setZenScale(scale - 0.1)
                : null,
          ),
          InkWell(
            onTap: () => PreferencesService.setZenScale(1.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${(scale * 100).round()}%',
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 14, color: EverforestColors.grey),
            tooltip: 'Zoom In',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: scale < 1.75
                ? () => PreferencesService.setZenScale(scale + 0.1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isMobile = screenWidth < 600;
        final isTablet = screenWidth >= 600 && screenWidth < 1024;

        return ValueListenableBuilder<double>(
          valueListenable: PreferencesService.zenScale,
          builder: (context, scale, _) {
            final double horizPadding = isMobile
                ? 12.0 * scale
                : (isTablet ? 24.0 * scale : 48.0 * scale);
            final double vertPadding = 24.0 * scale;

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: const Color(0xFF1E2326),
              drawer: isMobile ? Drawer(child: _buildSidebarContent()) : null,
              body: Row(
                children: [
                  // Sidebar Document Tree
                  if (!isMobile && _leftSidebarOpen) _buildSidebarContent(),

                  // Main Editor Area
                  Expanded(
                    child: Column(
                      children: [
                        // Top Tab Bar
                        Container(
                          height: 40,
                          color: const Color(0xFF272E33),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  isMobile
                                      ? Icons.menu
                                      : (_leftSidebarOpen ? Icons.chevron_left : Icons.chevron_right),
                                  color: EverforestColors.fg,
                                  size: 18,
                                ),
                                onPressed: () {
                                  if (isMobile) {
                                    _scaffoldKey.currentState?.openDrawer();
                                  } else {
                                    setState(() => _leftSidebarOpen = !_leftSidebarOpen);
                                  }
                                },
                              ),
                              Expanded(
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _openFilePaths.length,
                                  itemBuilder: (context, index) {
                                    final path = _openFilePaths[index];
                                    final fileName = path.split(RegExp(r'[/\\]')).last.replaceAll('.json', '').replaceAll('.md', '');
                                    final isActive = path == _activeFilePath;

                                    return GestureDetector(
                                      onTap: () => _openFile(path),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isActive ? const Color(0xFF1E2326) : Colors.transparent,
                                          border: Border(
                                            right: const BorderSide(color: Color(0xFF2E383C), width: 1),
                                            top: isActive
                                                ? const BorderSide(color: EverforestColors.green, width: 2)
                                                : BorderSide.none,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.article_outlined, size: 14, color: EverforestColors.green),
                                            const SizedBox(width: 6),
                                            Text(
                                              fileName,
                                              style: TextStyle(
                                                color: isActive ? EverforestColors.fg : EverforestColors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            InkWell(
                                              onTap: () => _closeTab(index),
                                              child: const Icon(Icons.close, size: 12, color: EverforestColors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.search, color: EverforestColors.green, size: 16),
                                tooltip: 'Search vault',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                onPressed: _showVaultSearchDialog,
                              ),
                              IconButton(
                                icon: const Icon(Icons.code, color: EverforestColors.green, size: 16),
                                tooltip: 'Extract to Markdown',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                onPressed: _editorState == null
                                    ? null
                                    : () => _showExtractMarkdown(),
                              ),
                              _buildScaleControls(scale),
                            ],
                          ),
                        ),

                        // AppFlowy Editor Engine Container
                        Expanded(
                          child: _editorState == null
                              ? const Center(
                                  child: Text(
                                    'No document open. Create or select a document to start.',
                                    style: TextStyle(color: EverforestColors.grey),
                                  ),
                                )
                              : FloatingToolbar(
                                  items: [
                                    zenCommentItem,
                                    paragraphItem,
                                    ...headingItems,
                                    formatItemById('editor.bold'),
                                    formatItemById('editor.underline'),
                                    formatItemById('editor.italic'),
                                    buildTextColorItem(),
                                    buildHighlightColorItem(),
                                    formatItemById('editor.code'),
                                    bulletedListItem,
                                    zenTodoListItem,
                                    numberedListItem,
                                    zenToggleItem,
                                    zenCalloutItem,
                                    quoteItem,
                                    linkItem,
                                    ...alignmentItems,
                                    zenFontItem,
                                    formatItemById('editor.strikethrough'),
                                    zenEquationItem,
                                  ],
                                  textDirection: TextDirection.ltr,
                                  editorState: _editorState!,
                                  editorScrollController: _editorScrollController!,
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.topCenter,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            maxWidth: isMobile ? double.infinity : (850.0 * scale),
                                          ),
                                          child: AppFlowyEditor(
                                            editorState: _editorState!,
                                            editorScrollController: _editorScrollController!,
                                            focusNode: _editorFocusNode,
                                            autoFocus: true,
                                            characterShortcutEvents: [
                                              customAppFlowySlashCommand,
                                              wikiLinkShortcutEvent,
                                              zenImageShortcutEvent,
                                              formatDoubleEqualsToHighlight,
                                              ...standardCharacterShortcutEvents,
                                            ],
                                            commandShortcutEvents: [
                                              customMoveCursorUpCommand,
                                              customMoveCursorDownCommand,
                                              customPasteCommand,
                                              customCopyCommand,
                                              ...standardCommandShortcutEvents,
                                            ],
                                            blockComponentBuilders: {
                                              ...standardBlockComponentBuilderMap,
                                              ParagraphBlockKeys.type: ParagraphBlockComponentBuilder(
                                                configuration: standardBlockComponentConfiguration.copyWith(
                                                  padding: (_) =>
                                                      const EdgeInsets.symmetric(vertical: 1.0),
                                                ),
                                              ),
                                              CalloutBlockKeys.type: CalloutBlockComponentBuilder(),
                                              CodeBlockKeys.type: CodeBlockComponentBuilder(),
                                              ToggleBlockKeys.type: ToggleBlockComponentBuilder(),
                                              ZenEmbedKeys.type: ZenEmbedBlockComponentBuilder(),
                                              HeadingBlockKeys.type: HeadingBlockComponentBuilder(
                                                textStyleBuilder: (level) {
                                                  const baseSizes = [28.0, 24.0, 20.0, 18.0, 16.0, 14.0];
                                                  const colors = [
                                                    EverforestColors.green,
                                                    EverforestColors.blue,
                                                    EverforestColors.purple,
                                                    EverforestColors.orange,
                                                    EverforestColors.fg,
                                                    EverforestColors.fg,
                                                  ];
                                                  final base = baseSizes.elementAtOrNull(level - 1) ?? 16.0;
                                                  return TextStyle(
                                                    color: colors.elementAtOrNull(level - 1) ?? EverforestColors.fg,
                                                    fontSize: (base * scale).clamp(12.0, 48.0),
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.25,
                                                    leadingDistribution: TextLeadingDistribution.even,
                                                  );
                                                },
                                              ),
                                            },
                                            editorStyle: (isMobile ? EditorStyle.mobile : EditorStyle.desktop)(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: horizPadding.clamp(8.0, 64.0),
                                                vertical: vertPadding.clamp(12.0, 48.0),
                                              ),
                                              cursorColor: EverforestColors.green,
                                              selectionColor: EverforestColors.bg2,
                                              textStyleConfiguration: TextStyleConfiguration(
                                                text: TextStyle(
                                                  color: EverforestColors.fg,
                                                  fontSize: (16.0 * scale).clamp(11.0, 32.0),
                                                  height: 1.25,
                                                  leadingDistribution: TextLeadingDistribution.even,
                                                ),
                                                bold: TextStyle(
                                                  color: EverforestColors.fg,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: (16.0 * scale).clamp(11.0, 32.0),
                                                  height: 1.25,
                                                  leadingDistribution: TextLeadingDistribution.even,
                                                ),
                                                italic: TextStyle(
                                                  color: EverforestColors.green,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: (16.0 * scale).clamp(11.0, 32.0),
                                                  height: 1.25,
                                                  leadingDistribution: TextLeadingDistribution.even,
                                                ),
                                                strikethrough: TextStyle(
                                                  color: EverforestColors.grey,
                                                  decoration: TextDecoration.lineThrough,
                                                  fontSize: (16.0 * scale).clamp(11.0, 32.0),
                                                  height: 1.25,
                                                  leadingDistribution: TextLeadingDistribution.even,
                                                ),
                                                code: TextStyle(
                                                  color: EverforestColors.orange,
                                                  fontFamily: 'JetBrainsMono',
                                                  backgroundColor: const Color(0x332E383C),
                                                  fontSize: (14.0 * scale).clamp(10.0, 28.0),
                                                  height: 1.25,
                                                  leadingDistribution: TextLeadingDistribution.even,
                                                ),
                                              ),
                                              textSpanDecorator: (context, node, index, text, textSpan) {
                                                final attributes = text.attributes;
                                                var span = defaultTextSpanDecoratorForAttribute(context, node, index, text, textSpan);
                                                if (attributes != null) {
                                                  final bgColor = attributes[AppFlowyRichTextKeys.highlightColor] ??
                                                      attributes['highlight'] ??
                                                      attributes['bg_color'];
                                                  if (bgColor != null) {
                                                    final style = span.style?.copyWith(
                                                      backgroundColor: const Color(0x40A7C080),
                                                      color: EverforestColors.green,
                                                      height: 1.1,
                                                      leadingDistribution: TextLeadingDistribution.even,
                                                    ) ?? const TextStyle(
                                                      backgroundColor: Color(0x40A7C080),
                                                      color: EverforestColors.green,
                                                      height: 1.1,
                                                      leadingDistribution: TextLeadingDistribution.even,
                                                    );
                                                    span = TextSpan(
                                                      text: span.text,
                                                      children: span.children,
                                                      style: style,
                                                      recognizer: span.recognizer,
                                                    );
                                                  }
                                                }
                                                final delta = node.delta;
                                                if (delta != null && text.text.isNotEmpty) {
                                                  final start = index;
                                                  final end = index + text.text.length;
                                                  final plain = delta.toPlainText();
                                                  for (final match in _wikiLinkRegExp.allMatches(plain)) {
                                                    if (start < match.end && end > match.start) {
                                                      final target = match.group(1) ?? '';
                                                      final style = (span.style ?? const TextStyle()).copyWith(
                                                        color: EverforestColors.blue,
                                                        decoration: TextDecoration.underline,
                                                        decorationColor: EverforestColors.blue,
                                                      );
                                                      span = TextSpan(
                                                        text: span.text,
                                                        children: span.children,
                                                        style: style,
                                                        recognizer: TapGestureRecognizer()
                                                          ..onTap = () => _handleZenLink(target),
                                                        mouseCursor: SystemMouseCursors.click,
                                                      );
                                                      break;
                                                    }
                                                  }
                                                }
                                                return span;
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      RemoteCursorOverlay(
                                        editorState: _editorState!,
                                        scrollController: _editorScrollController!,
                                        presences: _remotePresences,
                                      ),
                                    ],
                                  ),
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
      },
    );
  }

  String _parent(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    return parts.sublist(0, parts.length - 1).join('/');
  }

  void _renameFile(String path, String newName) {
    final fs = ZenFileSystem.instance;
    final sanitized = newName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (sanitized.isEmpty) return;
    final isDir = fs.isDirectory(path);
    final parent = _parent(path);
    final ext = isDir ? '' : _extension(path);
    final newPath = '$parent/$sanitized$ext';
    if (newPath == path) return;
    if (fs.exists(newPath)) return;
    try {
      fs.rename(path, newPath);
      _remapOpenPath(path, newPath);
    } catch (e) {
      debugPrint('Rename failed: $e');
    }
    if (!kIsWeb) {
      ZenSyncService.instance.deleteByFullPath(path);
      if (!isDir) ZenSyncService.instance.upsertNodeFromDisk(newPath);
    }
    _refreshFileTree();
  }

  void _duplicateFile(String path) {
    final fs = ZenFileSystem.instance;
    final isDir = fs.isDirectory(path);
    final base = _basenameNoExt(path);
    final ext = isDir ? '' : _extension(path);
    final parent = _parent(path);
    String target = '$parent/$base (copy)$ext';
    var i = 1;
    while (fs.exists(target)) {
      target = '$parent/$base (copy $i)$ext';
      i++;
    }
    try {
      fs.copy(path, target);
      if (!isDir && !kIsWeb) ZenSyncService.instance.upsertNodeFromDisk(target);
    } catch (e) {
      debugPrint('Duplicate failed: $e');
    }
    _refreshFileTree();
  }

  void _deleteFile(String path) {
    try {
      ZenFileSystem.instance.delete(path);
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
    if (!kIsWeb) ZenSyncService.instance.deleteByFullPath(path);
    final norm = path.replaceAll('\\', '/');
    _openFilePaths.removeWhere((p) {
      final n = p.replaceAll('\\', '/');
      return n == norm || n.startsWith('$norm/');
    });
    final activeNorm = _activeFilePath?.replaceAll('\\', '/');
    final stillOpen = activeNorm != null &&
        _openFilePaths.any((p) => p.replaceAll('\\', '/') == activeNorm);
    if (activeNorm != null && !stillOpen) {
      if (_openFilePaths.isNotEmpty) {
        _openFile(_openFilePaths.first);
      } else {
        _disposeCollab();
        _activeFilePath = null;
        _editorState = null;
      }
    }
    _refreshFileTree();
  }

  void _moveFile(String path, String targetParentPath) {
    final fs = ZenFileSystem.instance;
    final target = targetParentPath.isEmpty ? _workspacePath : targetParentPath;
    if (path == target) return;
    final normPath = path.replaceAll('\\', '/');
    final normTarget = target.replaceAll('\\', '/');
    if (normTarget.startsWith('$normPath/')) return;
    final name = _basename(path);
    final newPath = '$target/$name';
    if (fs.exists(newPath)) return;
    try {
      fs.rename(path, newPath);
      _remapOpenPath(path, newPath);
    } catch (e) {
      debugPrint('Move failed: $e');
    }
    final isDir = fs.isDirectory(newPath);
    if (!kIsWeb) {
      ZenSyncService.instance.deleteByFullPath(path);
      if (!isDir) ZenSyncService.instance.upsertNodeFromDisk(newPath);
    }
    _refreshFileTree();
  }

  void _remapOpenPath(String oldPath, String newPath) {
    final oldNorm = oldPath.replaceAll('\\', '/');
    final newNorm = newPath.replaceAll('\\', '/');
    for (var i = 0; i < _openFilePaths.length; i++) {
      final p = _openFilePaths[i].replaceAll('\\', '/');
      if (p == oldNorm || p.startsWith('$oldNorm/')) {
        _openFilePaths[i] = '$newNorm${p.substring(oldNorm.length)}';
      }
    }
    final a = _activeFilePath?.replaceAll('\\', '/');
    if (a != null && (a == oldNorm || a.startsWith('$oldNorm/'))) {
      _activeFilePath = '$newNorm${a.substring(oldNorm.length)}';
    }
  }
}

