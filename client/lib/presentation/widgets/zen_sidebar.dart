import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/obsidian/zen_file_system.dart';
import '../../database/preferences_service.dart';
import 'zen_sidebar/zen_sidebar_components.dart';
import 'zen_sidebar/zen_tree_item.dart';

export 'zen_sidebar/zen_sidebar_components.dart';
export 'zen_sidebar/zen_tree_item.dart';

class ZenSidebar extends StatefulWidget {
  const ZenSidebar({
    super.key,
    required this.tree,
    required this.activePath,
    required this.onOpen,
    required this.onCreateFile,
    required this.onCreateFolder,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onMove,
    this.onChanged,
  });

  final List<FileNode> tree;
  final String? activePath;
  final void Function(String path) onOpen;
  final Future<void> Function(String parentFolderPath) onCreateFile;
  final Future<void> Function(String parentFolderPath) onCreateFolder;
  final void Function(String path, String newName) onRename;
  final void Function(String path) onDuplicate;
  final void Function(String path) onDelete;
  final void Function(String path, String targetParentPath) onMove;
  final VoidCallback? onChanged;

  @override
  State<ZenSidebar> createState() => _ZenSidebarState();
}

class _ZenSidebarState extends State<ZenSidebar> {
  final Map<String, bool> _sections = {'pages': true, 'favorites': true};
  late Set<String> _expanded = {
    ...PreferencesService.zenExpanded.value.map((p) => p.replaceAll('\\', '/')),
  };
  String? _editingPath;
  final TextEditingController _editController = TextEditingController();

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  String _norm(String p) => p.replaceAll('\\', '/');

  void _toggleExpand(String path) {
    final key = _norm(path);
    setState(() {
      if (!_expanded.remove(key)) _expanded.add(key);
    });
    PreferencesService.setZenExpanded(_expanded.toList());
  }

  void _collapseAll() {
    setState(() => _expanded.clear());
    PreferencesService.setZenExpanded([]);
  }

  List<FileNode> _collectFavorites(List<FileNode> nodes, List<FileNode> out) {
    for (final n in nodes) {
      if (PreferencesService.zenFavorites.value.contains(_norm(n.path))) {
        out.add(n);
      }
      _collectFavorites(n.children, out);
    }
    return out;
  }

  Future<void> _showCreateFileDialog(String parent) =>
      widget.onCreateFile(parent);

  void _handleItemChanged() {
    widget.onChanged?.call();
    PreferencesService.setZenExpanded(_expanded.toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _collectFavorites(widget.tree, []);
    return Column(
      children: [
        Expanded(
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) => widget.onMove(details.data, ''),
            builder: (context, candidates, rejects) {
              final hovering = candidates.isNotEmpty;
              return Container(
                decoration: BoxDecoration(
                  color: hovering
                      ? kZenDragHighlight.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: hovering
                      ? Border.all(color: kZenDragHighlight.withValues(alpha: 0.6), width: 1.5)
                      : Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  children: [
                    if (favorites.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Favorites',
                        showAdd: false,
                        onCollapseAll: () {},
                        onAdd: () {},
                      ),
                      ...favorites.map((n) => ZenTreeItem(
                            node: n,
                            level: 0,
                            isFirstChild: true,
                            activePath: widget.activePath,
                            editingPath: _editingPath,
                            expanded: _expanded,
                            editController: _editController,
                            onOpen: widget.onOpen,
                            onCreateFile: _showCreateFileDialog,
                            onCreateFolder: widget.onCreateFolder,
                            onRename: (path, name) {
                              setState(() => _editingPath = null);
                              widget.onRename(path, name);
                            },
                            onDuplicate: widget.onDuplicate,
                            onDelete: widget.onDelete,
                            onMove: widget.onMove,
                            onToggleExpand: _toggleExpand,
                            onStartRename: (path, name) {
                              setState(() {
                                _editingPath = path;
                                _editController.text = name;
                              });
                            },
                            onCancelRename: () => setState(() => _editingPath = null),
                            onChanged: _handleItemChanged,
                          )),
                      const Divider(height: 1, color: Color(0xFF2E383C)),
                    ],
                    SectionHeader(
                      title: 'Pages',
                      showAdd: true,
                      expanded: _sections['pages'] == true,
                      onToggleExpanded: () =>
                          setState(() => _sections['pages'] = _sections['pages'] != true),
                      onCollapseAll: _collapseAll,
                      onAdd: () => _showCreateFileDialog(''),
                    ),
                    if (_sections['pages'] == true)
                      ...widget.tree.map((n) => ZenTreeItem(
                            node: n,
                            level: 0,
                            isFirstChild: n == widget.tree.first,
                            activePath: widget.activePath,
                            editingPath: _editingPath,
                            expanded: _expanded,
                            editController: _editController,
                            onOpen: widget.onOpen,
                            onCreateFile: _showCreateFileDialog,
                            onCreateFolder: widget.onCreateFolder,
                            onRename: (path, name) {
                              setState(() => _editingPath = null);
                              widget.onRename(path, name);
                            },
                            onDuplicate: widget.onDuplicate,
                            onDelete: widget.onDelete,
                            onMove: widget.onMove,
                            onToggleExpand: _toggleExpand,
                            onStartRename: (path, name) {
                              setState(() {
                                _editingPath = path;
                                _editController.text = name;
                              });
                            },
                            onCancelRename: () => setState(() => _editingPath = null),
                            onChanged: _handleItemChanged,
                          )),
                  ],
                ),
              );
            },
          ),
        ),
        const Divider(height: 1, color: Color(0xFF2E383C)),
        ZenNewPageButton(onPressed: () => _showCreateFileDialog('')),
      ],
    );
  }
}
