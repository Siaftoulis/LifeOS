import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';

class CHTMMemoView extends StatefulWidget {
  const CHTMMemoView({super.key});

  @override
  State<CHTMMemoView> createState() => _CHTMMemoViewState();
}

class _CHTMMemoViewState extends State<CHTMMemoView> {
  final db = AppDatabase.instance;

  // Local helper to parse color
  Color _parseColor(String hex) {
    try {
      final code = hex.replaceAll('#', '');
      return Color(int.parse('FF$code', radix: 16));
    } catch (_) {
      return EverforestColors.green;
    }
  }

  // Load and save functions
  Stream<List<MemoList>> _watchMemos() {
    return (db.select(db.systemSettings)..where((t) => t.key.equals('chtm_memos')))
        .watchSingleOrNull()
        .map((setting) {
      if (setting == null || setting.value.isEmpty) return [];
      try {
        final List<dynamic> decoded = jsonDecode(setting.value);
        return decoded.map((item) => MemoList.fromJson(item)).toList();
      } catch (_) {
        return [];
      }
    });
  }

  Future<void> _saveMemos(List<MemoList> lists) async {
    final jsonStr = jsonEncode(lists.map((l) => l.toJson()).toList());
    await db.into(db.systemSettings).insertOnConflictUpdate(
          SystemSettingsCompanion(
            key: const drift.Value('chtm_memos'),
            value: drift.Value(jsonStr),
            updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
            isDirty: const drift.Value(1),
          ),
        );
  }

  void _addNewList() async {
    final controller = TextEditingController();
    String selectedColor = '#A6E3A1'; // Everforest Green default

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: EverforestColors.bg0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('New Checklist Memo', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: EverforestColors.fg),
                    decoration: const InputDecoration(
                      labelText: 'Memo Title',
                      labelStyle: TextStyle(color: EverforestColors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Theme Color', style: TextStyle(color: EverforestColors.fg)),
                      Row(
                        children: [
                          _colorBtn(setDialogState, '#A6E3A1', EverforestColors.green, selectedColor),
                          _colorBtn(setDialogState, '#89B4FA', EverforestColors.blue, selectedColor),
                          _colorBtn(setDialogState, '#F38BA8', EverforestColors.red, selectedColor),
                          _colorBtn(setDialogState, '#F9E2AF', EverforestColors.yellow, selectedColor),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EverforestColors.green,
                    foregroundColor: EverforestColors.bg0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && controller.text.trim().isNotEmpty) {
      // Load current lists, add new, save
      final currentList = await _watchMemos().first;
      final newList = MemoList(
        id: const Uuid().v4(),
        title: controller.text.trim(),
        colorHex: selectedColor,
        items: [],
      );
      await _saveMemos([...currentList, newList]);
    }
  }

  Widget _colorBtn(StateSetter setDialogState, String code, Color color, String currentSelected) {
    final isSelected = code == currentSelected;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          // Note: state updates in dialog need dialogState
        });
        setState(() {
          // updates state
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemoList>>(
      stream: _watchMemos(),
      builder: (context, snapshot) {
        final lists = snapshot.data ?? [];

        return Scaffold(
          backgroundColor: EverforestColors.bg0,
          body: lists.isEmpty
              ? _buildEmptyState()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: lists.length,
                      itemBuilder: (context, index) {
                        final memo = lists[index];
                        return _buildMemoCard(memo, lists);
                      },
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addNewList,
            backgroundColor: EverforestColors.green,
            foregroundColor: EverforestColors.bg0,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_alt_outlined, size: 64, color: EverforestColors.grey),
          const SizedBox(height: 16),
          const Text(
            'No checklist memos created yet',
            style: TextStyle(color: EverforestColors.grey, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addNewList,
            icon: const Icon(Icons.add),
            label: const Text('Create Memo List'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.green,
              foregroundColor: EverforestColors.bg0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoCard(MemoList memo, List<MemoList> allLists) {
    final Color color = _parseColor(memo.colorHex);
    final completedCount = memo.items.where((i) => i.isDone).length;
    final totalCount = memo.items.length;
    final progressStr = totalCount > 0 ? '$completedCount/$totalCount Completed' : 'Empty';

    final textController = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  memo.title,
                  style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: EverforestColors.red, size: 20),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: EverforestColors.bg0,
                      title: const Text('Delete List?', style: TextStyle(color: EverforestColors.fg)),
                      actions: [
                        TextButton(
                          child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        TextButton(
                          child: const Text('Delete', style: TextStyle(color: EverforestColors.red)),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    final updated = allLists.where((l) => l.id != memo.id).toList();
                    await _saveMemos(updated);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Progress bar/text
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                progressStr,
                style: TextStyle(color: EverforestColors.grey, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Item List
          Expanded(
            child: ListView.builder(
              itemCount: memo.items.length,
              itemBuilder: (context, idx) {
                final item = memo.items[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          item.isDone = !item.isDone;
                          await _saveMemos(allLists);
                        },
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: item.isDone ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: item.isDone ? color : EverforestColors.grey, width: 2),
                          ),
                          child: item.isDone
                              ? const Icon(Icons.check, color: EverforestColors.bg0, size: 14)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            color: item.isDone ? EverforestColors.grey : EverforestColors.fg,
                            fontSize: 14,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: EverforestColors.grey, size: 16),
                        onPressed: () async {
                          memo.items.removeAt(idx);
                          await _saveMemos(allLists);
                        },
                      )
                    ],
                  ),
                );
              },
            ),
          ),
          // Quick Add Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Add list item...',
                    hintStyle: TextStyle(color: EverforestColors.grey, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (val) async {
                    if (val.trim().isEmpty) return;
                    memo.items.add(MemoItem(
                      id: const Uuid().v4(),
                      title: val.trim(),
                      isDone: false,
                    ));
                    await _saveMemos(allLists);
                    textController.clear();
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: color, size: 18),
                onPressed: () async {
                  final val = textController.text.trim();
                  if (val.isEmpty) return;
                  memo.items.add(MemoItem(
                    id: const Uuid().v4(),
                    title: val,
                    isDone: false,
                  ));
                  await _saveMemos(allLists);
                  textController.clear();
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}

class MemoList {
  final String id;
  final String title;
  final String colorHex;
  final List<MemoItem> items;

  MemoList({
    required this.id,
    required this.title,
    required this.colorHex,
    required this.items,
  });

  factory MemoList.fromJson(Map<String, dynamic> json) {
    return MemoList(
      id: json['id'],
      title: json['title'],
      colorHex: json['colorHex'] ?? '#A6E3A1',
      items: (json['items'] as List<dynamic>)
          .map((i) => MemoItem.fromJson(i))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'colorHex': colorHex,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class MemoItem {
  final String id;
  final String title;
  bool isDone;

  MemoItem({
    required this.id,
    required this.title,
    required this.isDone,
  });

  factory MemoItem.fromJson(Map<String, dynamic> json) {
    return MemoItem(
      id: json['id'],
      title: json['title'],
      isDone: json['isDone'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }
}
