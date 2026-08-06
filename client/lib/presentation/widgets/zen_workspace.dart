import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/command/copy_paste_extension.dart';

import '../../appflowy/src/editor/block_component/callout_block_component/callout_block_component.dart';
import '../../appflowy/src/editor/block_component/code_block_component/code_block_component.dart';
import '../../appflowy/src/editor/block_component/toggle_block_component/toggle_block_component.dart';
import '../../appflowy/src/editor/selection_menu/selection_menu_service.dart';
import '../../appflowy/src/editor/wiki_link_shortcut.dart';
import '../../theme/everforest_colors.dart';
import '../../database/preferences_service.dart';
import '../theme/zen_markdown_bridge.dart';
import '../widgets/maps_live_tracking/maps_dashboard_widget.dart';
import '../widgets/media_hub/movie_library/movie_library_dashboard.dart';
import '../widgets/book_library/book_library_dashboard.dart';
import '../../plugins/gallery/gallery_home_view.dart';
import 'zen_sidebar.dart';

final _wikiLinkRegExp = RegExp(r'\[\[([^\[\]\n]+)\]\]');

final formatDoubleEqualsToHighlight = CharacterShortcutEvent(
  key: 'format double equals to gold highlight',
  character: '=',
  handler: (editorState) async {
    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed || selection.end.offset < 4) {
      return false;
    }

    final path = selection.end.path;
    final node = editorState.getNodeAtPath(path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return false;
    }

    final plainText = delta.toPlainText();
    if (plainText.length < 4 || plainText[selection.end.offset - 1] != '=') {
      return false;
    }

    final charIndexList = <int>[];
    for (var i = 0; i < plainText.length; i++) {
      if (plainText[i] == '=') {
        charIndexList.add(i);
      }
    }

    if (charIndexList.length < 3) {
      return false;
    }

    final thirdLastCharIndex = charIndexList[charIndexList.length - 3];
    final secondLastCharIndex = charIndexList[charIndexList.length - 2];
    final lastCharIndex = charIndexList[charIndexList.length - 1];

    if (secondLastCharIndex != thirdLastCharIndex + 1 ||
        lastCharIndex == secondLastCharIndex + 1) {
      return false;
    }

    final deletion = editorState.transaction
      ..deleteText(node, lastCharIndex, 1)
      ..deleteText(node, thirdLastCharIndex, 2);
    editorState.apply(deletion);

    final format = editorState.transaction
      ..formatText(
        node,
        thirdLastCharIndex,
        selection.end.offset - thirdLastCharIndex - 3,
        {
          'bg_color': '0x40DBBC7F',
        },
      )
      ..afterSelection = Selection.collapsed(
        Position(
          path: path,
          offset: selection.end.offset - 3,
        ),
      );
    editorState.apply(format);
    editorState.toggledStyle.clear();
    return true;
  },
);

final customMoveCursorUpCommand = CommandShortcutEvent(
  key: 'custom move cursor upward',
  command: 'arrow up',
  macOSCommand: 'arrow up',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }

    final rects = editorState.selectionRects();
    final currentPosition = selection.end;
    final currentNode = editorState.getNodeAtPath(currentPosition.path);

    Position? upPosition;

    final pos1 = currentPosition.moveVertical(editorState, upwards: true);
    if (pos1 != null && pos1 != currentPosition) {
      upPosition = pos1;
    }

    if (upPosition == null && rects.isNotEmpty) {
      final rect = rects.reduce((c, n) => c.top <= n.top ? c : n);
      final testOffsets = [
        rect.topLeft.translate(0, -rect.height * 1.5),
        rect.topLeft.translate(0, -rect.height * 2.0),
        rect.topLeft.translate(0, -rect.height * 2.5 - 10),
        rect.topLeft.translate(0, -32.0),
        rect.topLeft.translate(0, -50.0),
      ];

      for (final testOffset in testOffsets) {
        final candidate = editorState.service.selectionService.getPositionInOffset(testOffset);
        if (candidate != null && candidate != currentPosition) {
          upPosition = candidate;
          break;
        }
      }
    }

    if (upPosition == null && currentNode != null) {
      final prevNode = currentNode.previous;
      if (prevNode != null) {
        upPosition = prevNode.selectable?.end();
      } else if (currentNode.parent != null) {
        final parentPrev = currentNode.parent?.previous;
        upPosition = parentPrev?.selectable?.end();
      }
    }

    if (upPosition != null) {
      editorState.updateSelectionWithReason(
        Selection.collapsed(upPosition),
        reason: SelectionUpdateReason.uiEvent,
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  },
);

final customMoveCursorDownCommand = CommandShortcutEvent(
  key: 'custom move cursor downward',
  command: 'arrow down',
  macOSCommand: 'arrow down',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }

    final rects = editorState.selectionRects();
    final currentPosition = selection.end;
    final currentNode = editorState.getNodeAtPath(currentPosition.path);

    Position? downPosition;

    final pos1 = currentPosition.moveVertical(editorState, upwards: false);
    if (pos1 != null && pos1 != currentPosition) {
      downPosition = pos1;
    }

    if (downPosition == null && rects.isNotEmpty) {
      final rect = rects.reduce((c, n) => c.bottom >= n.bottom ? c : n);
      final testOffsets = [
        rect.bottomLeft.translate(0, rect.height * 1.5),
        rect.bottomLeft.translate(0, rect.height * 2.0),
        rect.bottomLeft.translate(0, rect.height * 2.5 + 10),
        rect.bottomLeft.translate(0, 32.0),
        rect.bottomLeft.translate(0, 50.0),
      ];

      for (final testOffset in testOffsets) {
        final candidate = editorState.service.selectionService.getPositionInOffset(testOffset);
        if (candidate != null && candidate != currentPosition) {
          downPosition = candidate;
          break;
        }
      }
    }

    if (downPosition == null && currentNode != null) {
      final nextNode = currentNode.next;
      if (nextNode != null) {
        downPosition = nextNode.selectable?.start();
      } else if (currentNode.parent != null) {
        final parentNext = currentNode.parent?.next;
        downPosition = parentNext?.selectable?.start();
      }
    }

    if (downPosition != null) {
      editorState.updateSelectionWithReason(
        Selection.collapsed(downPosition),
        reason: SelectionUpdateReason.uiEvent,
      );
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  },
);

final customCopyCommand = CommandShortcutEvent(
  key: 'copy as markdown',
  command: 'ctrl+c',
  macOSCommand: 'cmd+c',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null || selection.isCollapsed) {
      return KeyEventResult.ignored;
    }
    // Top-level blocks only; the table keeps its cells. Cells flattened by
    // getNodesInSelection would be serialized twice.
    final originalNodes = editorState
        .getNodesInSelection(selection)
        .where((n) => n.parent?.type == PageBlockKeys.type)
        .toList();
    if (originalNodes.isEmpty) {
      return KeyEventResult.ignored;
    }

    () async {
      // Slice partial first/last blocks to the selection bounds.
      final single = originalNodes.length == 1;
      final first = originalNodes.first;
      final last = originalNodes.last;
      final nodes = originalNodes.toList();
      if (first.delta != null && selection.startIndex > 0) {
        final plain = first.delta!
            .slice(selection.startIndex,
                single ? selection.endIndex : first.delta!.length)
            .toPlainText();
        nodes[0] = paragraphNode(text: plain);
      }
      if (!single && last.delta != null && selection.endIndex < last.delta!.length) {
        final plain = last.delta!
            .slice(0, selection.endIndex)
            .toPlainText();
        nodes[nodes.length - 1] = paragraphNode(text: plain);
      }

      await AppFlowyClipboard.setData(
        text: ZenMarkdownBridge.exportMarkdownForNodes(nodes),
      );
    }();
    return KeyEventResult.handled;
  },
);

final customPasteCommand = CommandShortcutEvent(
  key: 'paste markdown or rich content',
  command: 'ctrl+v',
  macOSCommand: 'cmd+v',
  handler: (editorState) {
    final selection = editorState.selection;
    if (selection == null) {
      return KeyEventResult.ignored;
    }

    () async {
      final data = await AppFlowyClipboard.getData();
      final text = data.text;

      if (text != null && text.isNotEmpty) {
        try {
          final doc = markdownToDocument(text);
          ZenMarkdownBridge.processHighlights(doc.root);
          final nodes = doc.root.children.toList();

          while (nodes.isNotEmpty && nodes.first.delta?.isEmpty == true) {
            nodes.removeAt(0);
          }
          while (nodes.isNotEmpty && nodes.last.delta?.isEmpty == true) {
            nodes.removeLast();
          }

          if (nodes.isNotEmpty) {
            await editorState.deleteSelectionIfNeeded();
            if (nodes.length == 1) {
              await editorState.pasteSingleLineNode(nodes.first);
            } else {
              await editorState.pasteMultiLineNodes(nodes);
            }
            return;
          }
        } catch (_) {
          // Fallback to default paste
        }
      }

      await pasteCommand.execute(editorState);
    }();

    return KeyEventResult.handled;
  },
);

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

  final String _vaultPath = 'vault';
  String _activeWorkspace = '';

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
    _editorState?.dispose();
    _editorScrollController?.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initWorkspace() async {
    final dir = Directory(_vaultPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _activeWorkspace = PreferencesService.zenWorkspace.value;
    if (_activeWorkspace.isNotEmpty) {
      Directory('$_vaultPath/workspaces/$_activeWorkspace').createSync(recursive: true);
    }
    ZenLinkState.workspacePath = _workspacePath;
    _refreshFileTree();
    _loadInitialDocument();
  }

  void _refreshFileTree() {
    setState(() {
      _fileTree = _scanDir(Directory(_workspacePath));
    });
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
        if (name == 'workspaces' && _activeWorkspace.isEmpty) continue;

        if (entity is Directory) {
          nodes.add(FileNode(
            name: name,
            path: entity.path,
            isDirectory: true,
            children: _scanDir(entity),
          ));
        } else if (entity is File && (name.endsWith('.md') || name.endsWith('.json'))) {
          nodes.add(FileNode(
            name: name.replaceAll('.md', '').replaceAll('.json', ''),
            path: entity.path,
            isDirectory: false,
            children: [],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${dir.path}: $e');
    }
    return nodes;
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
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final parentDir = parentFolderPath ?? _workspacePath;
    final baseFilePath = '$parentDir/$sanitizedTitle.json';

    String targetPath = baseFilePath;
    int counter = 1;
    while (File(targetPath).existsSync()) {
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

    final file = File(targetPath);
    file.writeAsStringSync(jsonEncode(initialDocument.toJson()));
    _refreshFileTree();
    _openFile(targetPath);
  }

  Future<void> _showCreateFileDialog({String? parentFolderPath}) async {
    final controller = TextEditingController(text: 'Untitled Document');
    final fileName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: const Text('Create New Document', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: EverforestColors.fg),
          decoration: const InputDecoration(
            hintText: 'Document Name',
            hintStyle: TextStyle(color: EverforestColors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green, width: 2)),
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
            child: const Text('Create', style: TextStyle(color: Color(0xFF1E2326), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (fileName != null && fileName.isNotEmpty) {
      _createNewDocument(fileName, parentFolderPath: parentFolderPath);
    }
  }

  Future<void> _showCreateFolderDialog({String? parentFolderPath}) async {
    final controller = TextEditingController(text: 'New Folder');
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: const Text('Create New Folder', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: EverforestColors.fg),
          decoration: const InputDecoration(
            hintText: 'Folder Name',
            hintStyle: TextStyle(color: EverforestColors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green, width: 2)),
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
            child: const Text('Create', style: TextStyle(color: Color(0xFF1E2326), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      final sanitized = folderName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final parentDir = parentFolderPath ?? _workspacePath;
      final newDirPath = '$parentDir/$sanitized';
      final dir = Directory(newDirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _refreshFileTree();
    }
  }

  List<String> _listWorkspaces() {
    final workspacesDir = Directory('$_vaultPath/workspaces');
    final List<String> names = [''];
    if (workspacesDir.existsSync()) {
      for (final e in workspacesDir.listSync()) {
        if (e is Directory && !e.path.split(RegExp(r'[/\\]')).last.startsWith('.')) {
          names.add(e.path.split(RegExp(r'[/\\]')).last);
        }
      }
    }
    names.sort();
    return names;
  }

  Future<void> _showWorkspaceMenu() async {
    final renderBox = _workspaceMenuKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final workspaceNames = _listWorkspaces();

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
      ],
    );

    if (result == null || result == _activeWorkspace) return;
    if (result == '__new__') {
      final name = await _showCreateWorkspaceDialog();
      if (name != null) _switchWorkspace(name);
    } else {
      _switchWorkspace(result);
    }
  }

  Future<String?> _showCreateWorkspaceDialog() async {
    final controller = TextEditingController(text: 'New Workspace');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: const Text('Create New Workspace', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: EverforestColors.fg),
          decoration: const InputDecoration(
            hintText: 'Workspace Name',
            hintStyle: TextStyle(color: EverforestColors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green, width: 2)),
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
            child: const Text('Create', style: TextStyle(color: Color(0xFF1E2326), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return null;
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  void _switchWorkspace(String name) {
    Directory(name.isEmpty ? _vaultPath : '$_vaultPath/workspaces/$name')
        .createSync(recursive: true);
    _activeWorkspace = name;
    PreferencesService.setZenWorkspace(name);
    ZenLinkState.workspacePath = _workspacePath;

    _debounce?.cancel();
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
      if (zenLinkModules.containsKey(target)) {
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
    } else if (zenLinkModules.containsKey(type)) {
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
    final module = switch (type) {
      'maps' => _moduleShell('Maps', const MapsDashboardWidget()),
      'photos' => _moduleShell('Photos', const GalleryHomeView()),
      'books' => const BookLibraryDashboard(),
      'movies' => const MovieLibraryDashboard(),
      _ => null,
    };
    if (module == null) {
      _showLinkError('Unknown module "$type"');
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => module));
  }

  // Maps/photos have no AppBar of their own; without one there is no way back.
  Widget _moduleShell(String title, Widget child) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        title: Text(title, style: const TextStyle(color: EverforestColors.fg)),
      ),
      body: child,
    );
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
      final file = File(filePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
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
        File(_activeFilePath!).writeAsStringSync(jsonEncode(jsonMap));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2326),
      body: Row(
        children: [
          // Sidebar Document Tree
          if (_leftSidebarOpen)
            Container(
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
                      onOpen: _openFile,
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
            ),

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
                          _leftSidebarOpen ? Icons.chevron_left : Icons.chevron_right,
                          color: EverforestColors.fg,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _leftSidebarOpen = !_leftSidebarOpen),
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
                            paragraphItem,
                            ...headingItems,
                            ...markdownFormatItems,
                            quoteItem,
                            bulletedListItem,
                            numberedListItem,
                            linkItem,
                          ],
                          textDirection: TextDirection.ltr,
                          editorState: _editorState!,
                          editorScrollController: _editorScrollController!,
                          child: AppFlowyEditor(
                            editorState: _editorState!,
                            editorScrollController: _editorScrollController!,
                            focusNode: _editorFocusNode,
                            autoFocus: true,
                            characterShortcutEvents: [
                              customAppFlowySlashCommand,
                              wikiLinkShortcutEvent,
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
                              CalloutBlockKeys.type: CalloutBlockComponentBuilder(),
                              CodeBlockKeys.type: CodeBlockComponentBuilder(),
                              ToggleBlockKeys.type: ToggleBlockComponentBuilder(),
                              HeadingBlockKeys.type: HeadingBlockComponentBuilder(
                                textStyleBuilder: (level) {
                                  const sizes = [28.0, 24.0, 20.0, 18.0, 16.0, 14.0];
                                  const colors = [
                                    EverforestColors.green,
                                    EverforestColors.blue,
                                    EverforestColors.purple,
                                    EverforestColors.orange,
                                    EverforestColors.fg,
                                    EverforestColors.fg,
                                  ];
                                  return TextStyle(
                                    color: colors.elementAtOrNull(level - 1) ?? EverforestColors.fg,
                                    fontSize: sizes.elementAtOrNull(level - 1) ?? 16.0,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                    leadingDistribution: TextLeadingDistribution.even,
                                  );
                                },
                              ),
                            },
                            editorStyle: EditorStyle.desktop(
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                              cursorColor: EverforestColors.green,
                              selectionColor: EverforestColors.bg2,
                              textStyleConfiguration: const TextStyleConfiguration(
                                text: TextStyle(
                                  color: EverforestColors.fg,
                                  fontSize: 16,
                                  height: 1.25,
                                  leadingDistribution: TextLeadingDistribution.even,
                                ),
                                bold: TextStyle(
                                  color: EverforestColors.fg,
                                  fontWeight: FontWeight.bold,
                                  height: 1.25,
                                  leadingDistribution: TextLeadingDistribution.even,
                                ),
                                italic: TextStyle(
                                  color: EverforestColors.green,
                                  fontStyle: FontStyle.italic,
                                  height: 1.25,
                                  leadingDistribution: TextLeadingDistribution.even,
                                ),
                                strikethrough: TextStyle(
                                  color: EverforestColors.grey,
                                  decoration: TextDecoration.lineThrough,
                                  height: 1.25,
                                  leadingDistribution: TextLeadingDistribution.even,
                                ),
                                code: TextStyle(
                                  color: EverforestColors.orange,
                                  fontFamily: 'JetBrainsMono',
                                  backgroundColor: Color(0x332E383C),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  void _copyDirSync(Directory src, Directory dst) {
    dst.createSync(recursive: true);
    for (final entity in src.listSync()) {
      final name = _basename(entity.path);
      if (entity is Directory) {
        _copyDirSync(entity, Directory('${dst.path}/$name'));
      } else if (entity is File) {
        entity.copySync('${dst.path}/$name');
      }
    }
  }

  void _renameFile(String path, String newName) {
    final sanitized = newName.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    if (sanitized.isEmpty) return;
    final isDir = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
    final parent = File(path).parent.path;
    final ext = isDir ? '' : _extension(path);
    final newPath = '$parent/$sanitized$ext';
    if (newPath == path) return;
    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) return;
    try {
      if (isDir) {
        Directory(path).renameSync(newPath);
      } else {
        File(path).renameSync(newPath);
      }
      _remapOpenPath(path, newPath);
    } catch (e) {
      debugPrint('Rename failed: $e');
    }
    _refreshFileTree();
  }

  void _duplicateFile(String path) {
    final isDir = FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
    final base = _basenameNoExt(path);
    final ext = isDir ? '' : _extension(path);
    final parent = File(path).parent.path;
    String target = '$parent/$base (copy)$ext';
    var i = 1;
    while (FileSystemEntity.typeSync(target) != FileSystemEntityType.notFound) {
      target = '$parent/$base (copy $i)$ext';
      i++;
    }
    try {
      if (isDir) {
        _copyDirSync(Directory(path), Directory(target));
      } else {
        File(path).copySync(target);
      }
    } catch (e) {
      debugPrint('Duplicate failed: $e');
    }
    _refreshFileTree();
  }

  void _deleteFile(String path) {
    try {
      if (FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
        Directory(path).deleteSync(recursive: true);
      } else {
        File(path).deleteSync();
      }
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
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
        _activeFilePath = null;
        _editorState = null;
      }
    }
    _refreshFileTree();
  }

  void _moveFile(String path, String targetParentPath) {
    final target = targetParentPath.isEmpty ? _workspacePath : targetParentPath;
    if (path == target) return;
    final normPath = path.replaceAll('\\', '/');
    final normTarget = target.replaceAll('\\', '/');
    if (normTarget.startsWith('$normPath/')) return;
    final name = _basename(path);
    final newPath = '$target/$name';
    if (FileSystemEntity.typeSync(newPath) != FileSystemEntityType.notFound) return;
    try {
      if (FileSystemEntity.typeSync(path) == FileSystemEntityType.directory) {
        Directory(path).renameSync(newPath);
      } else {
        File(path).renameSync(newPath);
      }
      _remapOpenPath(path, newPath);
    } catch (e) {
      debugPrint('Move failed: $e');
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
