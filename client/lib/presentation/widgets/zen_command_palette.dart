import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';
import 'package:flutter/services.dart';

class CommandItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onExecute;

  CommandItem({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onExecute,
  });
}

class ZenCommandPalette extends StatefulWidget {
  final List<String> filePaths;
  final Function(String) onFileSelected;
  final List<CommandItem> extraCommands;

  const ZenCommandPalette({
    super.key,
    required this.filePaths,
    required this.onFileSelected,
    this.extraCommands = const [],
  });

  @override
  State<ZenCommandPalette> createState() => _ZenCommandPaletteState();
}

class _ZenCommandPaletteState extends State<ZenCommandPalette> {
  final TextEditingController _searchCtr = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommandItem> _filteredItems = [];
  List<CommandItem> _allItems = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildAllItems();
    _filteredItems = List.from(_allItems);
    _searchCtr.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _buildAllItems() {
    _allItems = [
      ...widget.extraCommands,
      ...widget.filePaths.map((path) => CommandItem(
        title: path.split('/').last.split('\\').last,
        subtitle: path,
        icon: Icons.description,
        onExecute: () => widget.onFileSelected(path),
      )),
    ];
  }

  void _onSearchChanged() {
    final query = _searchCtr.text.toLowerCase().trim();
    if (query.isEmpty) {
      setState(() {
        _filteredItems = List.from(_allItems);
        _selectedIndex = 0;
      });
      return;
    }

    setState(() {
      _filteredItems = _allItems.where((item) {
        return item.title.toLowerCase().contains(query) ||
            (item.subtitle?.toLowerCase().contains(query) ?? false);
      }).toList();
      _selectedIndex = 0;
    });
  }

  void _executeSelected() {
    if (_filteredItems.isEmpty) return;
    final item = _filteredItems[_selectedIndex];
    Navigator.of(context).pop();
    item.onExecute();
  }

  @override
  void dispose() {
    _searchCtr.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                if (_selectedIndex < _filteredItems.length - 1) {
                  _selectedIndex++;
                }
              });
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                if (_selectedIndex > 0) {
                  _selectedIndex--;
                }
              });
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              _executeSelected();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 450),
          decoration: BoxDecoration(
            color: EverforestColors.bg0,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EverforestColors.bg1, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: EverforestColors.grey, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchCtr,
                        focusNode: _focusNode,
                        style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Search files or execute commands...',
                          hintStyle: TextStyle(color: EverforestColors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onSubmitted: (_) => _executeSelected(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: EverforestColors.bg1, height: 1),
              if (_filteredItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No results found.', style: TextStyle(color: EverforestColors.grey)),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      final isSelected = index == _selectedIndex;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedIndex = index);
                          _executeSelected();
                        },
                        onHover: (hovering) {
                          if (hovering) {
                            setState(() => _selectedIndex = index);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          color: isSelected ? EverforestColors.bg1 : Colors.transparent,
                          child: Row(
                            children: [
                              Icon(item.icon, size: 16, color: isSelected ? EverforestColors.green : EverforestColors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        color: isSelected ? EverforestColors.fg : EverforestColors.fg.withValues(alpha: 0.8),
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    if (item.subtitle != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle!,
                                        style: TextStyle(
                                          color: EverforestColors.grey,
                                          fontSize: 11,
                                          fontFamily: 'JetBrainsMono',
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Text('⏎', style: TextStyle(color: EverforestColors.grey, fontSize: 16)),
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
      ),
    );
  }
}
