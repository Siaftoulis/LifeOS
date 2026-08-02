import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/editor_component/service/shortcuts/command/copy_paste_extension.dart';

import '../../appflowy/src/editor/block_component/callout_block_component/callout_block_component.dart';
import '../../appflowy/src/editor/block_component/code_block_component/code_block_component.dart';
import '../../appflowy/src/editor/block_component/toggle_block_component/toggle_block_component.dart';
import '../../appflowy/src/editor/selection_menu/selection_menu_service.dart';
import '../../appflowy/src/editor/wiki_link_shortcut.dart';
import '../../theme/everforest_colors.dart';
import '../theme/zen_markdown_bridge.dart';

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
    _refreshFileTree();
    _loadInitialDocument();
  }

  void _refreshFileTree() {
    setState(() {
      _fileTree = _scanDir(Directory(_vaultPath));
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
    final parentDir = parentFolderPath ?? _vaultPath;
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
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.yellow)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.yellow, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.yellow),
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
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.yellow)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.yellow, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.yellow),
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Create', style: TextStyle(color: Color(0xFF1E2326), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      final sanitized = folderName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final parentDir = parentFolderPath ?? _vaultPath;
      final newDirPath = '$parentDir/$sanitized';
      final dir = Directory(newDirPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _refreshFileTree();
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
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.edit_note, color: EverforestColors.yellow, size: 20),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Zen Editor',
                                  style: TextStyle(
                                    color: EverforestColors.fg,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: _fileTree.map((node) => _buildFileNodeItem(node)).toList(),
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
                                        ? const BorderSide(color: EverforestColors.yellow, width: 2)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.article_outlined, size: 14, color: EverforestColors.yellow),
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
                              customPasteCommand,
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
                                    EverforestColors.yellow,
                                    EverforestColors.green,
                                    EverforestColors.blue,
                                    EverforestColors.purple,
                                    EverforestColors.orange,
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
                              cursorColor: EverforestColors.yellow,
                              selectionColor: EverforestColors.bg2,
                              textStyleConfiguration: const TextStyleConfiguration(
                                text: TextStyle(
                                  color: EverforestColors.fg,
                                  fontSize: 16,
                                  height: 1.25,
                                  leadingDistribution: TextLeadingDistribution.even,
                                ),
                                bold: TextStyle(
                                  color: EverforestColors.yellow,
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
                                      backgroundColor: const Color(0x40DBBC7F),
                                      color: EverforestColors.yellow,
                                      height: 1.1,
                                      leadingDistribution: TextLeadingDistribution.even,
                                    ) ?? const TextStyle(
                                      backgroundColor: Color(0x40DBBC7F),
                                      color: EverforestColors.yellow,
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

  Widget _buildFileNodeItem(FileNode node) {
    if (node.isDirectory) {
      return Material(
        color: Colors.transparent,
        child: ExpansionTile(
          title: Text(node.name, style: const TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.w600)),
          leading: const Icon(Icons.folder_outlined, color: EverforestColors.yellow, size: 16),
          childrenPadding: const EdgeInsets.only(left: 12),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.note_add_outlined, size: 14, color: EverforestColors.grey),
                tooltip: 'New note in folder',
                onPressed: () => _showCreateFileDialog(parentFolderPath: node.path),
              ),
              const SizedBox(width: 6),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.create_new_folder_outlined, size: 14, color: EverforestColors.grey),
                tooltip: 'New subfolder',
                onPressed: () => _showCreateFolderDialog(parentFolderPath: node.path),
              ),
            ],
          ),
          children: node.children.map((c) => _buildFileNodeItem(c)).toList(),
        ),
      );
    }


    final isSelected = node.path == _activeFilePath;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        selected: isSelected,
        selectedTileColor: const Color(0xFF2A3236),
        leading: const Icon(Icons.description_outlined, color: EverforestColors.grey, size: 16),
        title: Text(
          node.name,
          style: TextStyle(
            color: isSelected ? EverforestColors.yellow : EverforestColors.fg,
            fontSize: 13,
          ),
        ),
        onTap: () => _openFile(node.path),
      ),
    );
  }

}
