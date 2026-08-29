import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/obsidian/zen_file_system.dart';
import '../../../database/preferences_service.dart';
import '../../../theme/everforest_colors.dart';
import 'zen_sidebar_components.dart';

class ZenTreeItem extends StatefulWidget {
  const ZenTreeItem({
    super.key,
    required this.node,
    required this.level,
    required this.isFirstChild,
    required this.activePath,
    required this.editingPath,
    required this.expanded,
    required this.editController,
    required this.onOpen,
    required this.onCreateFile,
    required this.onCreateFolder,
    required this.onRename,
    required this.onDuplicate,
    required this.onDelete,
    required this.onMove,
    required this.onToggleExpand,
    required this.onStartRename,
    required this.onCancelRename,
    required this.onChanged,
  });

  final FileNode node;
  final int level;
  final bool isFirstChild;
  final String? activePath;
  final String? editingPath;
  final Set<String> expanded;
  final TextEditingController editController;
  final void Function(String path) onOpen;
  final Future<void> Function(String parentFolderPath) onCreateFile;
  final Future<void> Function(String parentFolderPath) onCreateFolder;
  final void Function(String path, String newName) onRename;
  final void Function(String path) onDuplicate;
  final void Function(String path) onDelete;
  final void Function(String path, String targetParentPath) onMove;
  final void Function(String path) onToggleExpand;
  final void Function(String path, String name) onStartRename;
  final VoidCallback onCancelRename;
  final VoidCallback onChanged;

  @override
  State<ZenTreeItem> createState() => _ZenTreeItemState();
}

class _ZenTreeItemState extends State<ZenTreeItem> {
  DropPosition _position = DropPosition.none;
  bool _hovered = false;
  DateTime? _lastClickTime;
  static const _clickThrottle = Duration(milliseconds: 200);

  String _norm(String p) => p.replaceAll('\\', '/');

  bool get _isEditing => widget.editingPath == widget.node.path;

  bool _isDescendant(String ancestor, String maybeChild) {
    final a = _norm(ancestor);
    final c = _norm(maybeChild);
    return c != a && c.startsWith('$a/');
  }

  String? _parentOf(String path) {
    final parts = path.split(RegExp(r'[/\\]'));
    if (parts.length <= 1) return null;
    final parent = parts.sublist(0, parts.length - 1).join('/');
    return parent.isEmpty ? null : parent;
  }

  bool _accept(String dragPath, DropPosition pos) {
    if (dragPath == widget.node.path) return false;
    if (_isDescendant(widget.node.path, dragPath)) return false;
    if (pos == DropPosition.center && !widget.node.isDirectory) return false;
    return true;
  }

  void _drop(String dragPath, DropPosition pos) {
    final target = pos == DropPosition.center
        ? widget.node.path
        : _parentOf(widget.node.path) ?? '';
    widget.onMove(dragPath, target);
  }

  void _handleTap() {
    final now = DateTime.now();
    if (_lastClickTime != null &&
        now.difference(_lastClickTime!) < _clickThrottle) {
      return;
    }
    _lastClickTime = now;
    widget.onOpen(widget.node.path);
  }

  Future<void> _showMoreMenu(Offset position) async {
    final node = widget.node;
    final isFav =
        PreferencesService.zenFavorites.value.contains(_norm(node.path));
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx, position.dy),
      color: const Color(0xFF242B2E),
      elevation: 8,
      items: [
        if (node.isDirectory) ...[
          _menuItem('new_page', 'New page', Icons.note_add_outlined),
          _menuItem('new_folder', 'New folder', Icons.create_new_folder_outlined),
          const PopupMenuDivider(),
        ],
        _menuItem('rename', 'Rename', Icons.edit_outlined),
        _menuItem('duplicate', 'Duplicate', Icons.copy_outlined),
        _menuItem('favorite', isFav ? 'Remove from Favorites' : 'Add to Favorites',
            isFav ? Icons.star : Icons.star_border),
        if (node.isDirectory) ...[
          _menuItem('collapse_all', 'Collapse all pages', Icons.unfold_less),
        ],
        const PopupMenuDivider(),
        _menuItem('delete', 'Delete', Icons.delete_outline, red: true),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'new_page':
        await widget.onCreateFile(node.path);
        if (node.isDirectory) {
          widget.onToggleExpand(node.path);
        }
        break;
      case 'new_folder':
        await widget.onCreateFolder(node.path);
        break;
      case 'rename':
        widget.onStartRename(node.path, node.name);
        break;
      case 'duplicate':
        widget.onDuplicate(node.path);
        break;
      case 'favorite':
        await PreferencesService.toggleZenFavorite(_norm(node.path));
        widget.onChanged();
        break;
      case 'collapse_all':
        for (final child in node.children) {
          _collapseAllBelow(child);
        }
        widget.onChanged();
        break;
      case 'delete':
        if (await _confirmDelete(node)) {
          widget.onDelete(node.path);
        }
    }
  }

  void _collapseAllBelow(FileNode n) {
    if (widget.expanded.remove(_norm(n.path))) {}
    for (final c in n.children) {
      _collapseAllBelow(c);
    }
  }

  Future<bool> _confirmDelete(FileNode node) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242B2E),
        title: Text('Delete ${node.name}?',
            style: const TextStyle(color: EverforestColors.fg, fontSize: 16)),
        content: Text(
          node.isDirectory
              ? 'This will delete the folder and all pages inside it. This cannot be undone.'
              : 'This page will be permanently deleted. This cannot be undone.',
          style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: EverforestColors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon,
      {bool red = false}) {
    return PopupMenuItem(
      value: value,
      height: 32,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: red ? EverforestColors.red : EverforestColors.fg),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: red ? EverforestColors.red : EverforestColors.fg,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final selected = _norm(node.path) == _norm(widget.activePath ?? '');
    final hasChildren = node.children.isNotEmpty;
    final isExpanded = widget.expanded.contains(_norm(node.path));

    final row = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _isEditing ? null : _handleTap,
        child: SizedBox(
          height: kZenViewHeight,
          child: Padding(
            padding: EdgeInsets.only(left: widget.level * kZenLevelPadding),
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                if (event.buttons == kSecondaryMouseButton) {
                  _showMoreMenu(event.position);
                }
              },
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  if (hasChildren)
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => widget.onToggleExpand(node.path),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: Transform.rotate(
                          angle: isExpanded ? 0 : -1.5708,
                          child: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: isExpanded
                                ? EverforestColors.green
                                : EverforestColors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 2),
                  Icon(
                    node.isDirectory
                        ? (isExpanded
                            ? Icons.folder_open_outlined
                            : Icons.folder_outlined)
                        : Icons.description_outlined,
                    size: 16,
                    color: node.isDirectory
                        ? EverforestColors.green
                        : EverforestColors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _isEditing
                        ? _buildRenameField()
                        : Text(
                            node.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? EverforestColors.green
                                  : EverforestColors.fg,
                              fontSize: 14,
                              height: 1.0,
                            ),
                          ),
                  ),
                  if (_hovered) ...[
                    MoreIconButton(
                      icon: Icons.more_horiz,
                      tooltip: 'More actions',
                      onPressed: () {
                        final box = context.findRenderObject() as RenderBox?;
                        final pos = box?.localToGlobal(Offset(
                                box.size.width - 30, box.size.height / 2)) ??
                            Offset.zero;
                        _showMoreMenu(pos);
                      },
                    ),
                    const SizedBox(width: 8),
                    MoreIconButton(
                      icon: Icons.add,
                      tooltip: node.isDirectory
                          ? 'New page in folder'
                          : 'New page here',
                      onPressed: () async {
                        await widget.onCreateFile(
                            node.isDirectory
                                ? node.path
                                : _parentOf(node.path) ?? '');
                        if (node.isDirectory) widget.onToggleExpand(node.path);
                      },
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isFirstChild)
          Divider(
            height: kZenDragDividerHeight,
            thickness: kZenDragDividerHeight,
            color: _position == DropPosition.top
                ? kZenDragHighlight
                : Colors.transparent,
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: _position == DropPosition.center
                ? kZenDragHighlight.withValues(alpha: 0.5)
                : (selected || _hovered)
                    ? const Color(0xFF2A3236)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: row,
        ),
        Divider(
          height: kZenDragDividerHeight,
          thickness: kZenDragDividerHeight,
          color: _position == DropPosition.bottom
              ? kZenDragHighlight
              : Colors.transparent,
        ),
      ],
    );

    final draggable = Draggable<String>(
      data: node.path,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 250,
          decoration: BoxDecoration(
            color: const Color(0xFF242B2E),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(
                node.isDirectory
                    ? Icons.folder_outlined
                    : Icons.description_outlined,
                size: 14,
                color: node.isDirectory
                    ? EverforestColors.green
                    : EverforestColors.grey,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  node.name,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: EverforestColors.fg, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
      child: DragTarget<String>(
        onMove: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final local = box.globalToLocal(details.offset);
          final threshold = box.size.height / 5.0;
          final pos = (widget.isFirstChild && local.dy < -5.0)
              ? DropPosition.top
              : (local.dy > threshold ? DropPosition.bottom : DropPosition.center);
          final next = _accept(details.data, pos) ? pos : DropPosition.none;
          if (next != _position) setState(() => _position = next);
        },
        onLeave: (_) => setState(() => _position = DropPosition.none),
        onWillAcceptWithDetails: (details) =>
            _accept(details.data, DropPosition.center),
        onAcceptWithDetails: (details) {
          final pos = _position;
          setState(() => _position = DropPosition.none);
          _drop(details.data, pos == DropPosition.none ? DropPosition.bottom : pos);
        },
        builder: (context, candidates, rejects) => content,
      ),
    );

    if (isExpanded && hasChildren) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          draggable,
          ...node.children.map((child) => ZenTreeItem(
                node: child,
                level: widget.level + 1,
                isFirstChild: child == node.children.first,
                activePath: widget.activePath,
                editingPath: widget.editingPath,
                expanded: widget.expanded,
                editController: widget.editController,
                onOpen: widget.onOpen,
                onCreateFile: widget.onCreateFile,
                onCreateFolder: widget.onCreateFolder,
                onRename: widget.onRename,
                onDuplicate: widget.onDuplicate,
                onDelete: widget.onDelete,
                onMove: widget.onMove,
                onToggleExpand: widget.onToggleExpand,
                onStartRename: widget.onStartRename,
                onCancelRename: widget.onCancelRename,
                onChanged: widget.onChanged,
              )),
        ],
      );
    }

    return draggable;
  }

  Widget _buildRenameField() {
    return TextField(
      controller: widget.editController,
      autofocus: true,
      style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
      cursorColor: EverforestColors.green,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 4),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: EverforestColors.green)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: EverforestColors.green, width: 2)),
      ),
      onSubmitted: (value) => widget.onRename(nodePath, value.trim()),
      onTapOutside: (_) => widget.onCancelRename(),
    );
  }

  String get nodePath => widget.node.path;
}
