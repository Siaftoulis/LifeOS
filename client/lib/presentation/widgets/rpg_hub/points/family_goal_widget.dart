import 'package:flutter/material.dart';
import '../../../../api_client.dart';
import '../../../../theme/everforest_colors.dart';

class FamilyGoalWidget extends StatefulWidget {
  final bool isAdmin;
  const FamilyGoalWidget({super.key, required this.isAdmin});

  @override
  State<FamilyGoalWidget> createState() => _FamilyGoalWidgetState();
}

class _FamilyGoalWidgetState extends State<FamilyGoalWidget> {
  dynamic _mainQuest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMainQuest();
  }

  Future<void> _fetchMainQuest() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/rpg/quests');
      if (mounted) {
        setState(() {
          final allQuests = res as List<dynamic>;
          _mainQuest = allQuests.firstWhere(
            (q) => q['status'] == 'MAIN',
            orElse: () => null,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching main quest: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: EverforestColors.bg1.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
            child: CircularProgressIndicator(color: EverforestColors.yellow)),
      );
    }

    if (_mainQuest == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: EverforestColors.bg1.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: EverforestColors.yellow.withValues(alpha: 0.3)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            const Text('No active Main Quest.',
                style: TextStyle(color: EverforestColors.yellow, fontSize: 16)),
            if (widget.isAdmin)
              ElevatedButton.icon(
                icon: const Icon(Icons.flag, size: 16),
                label: const Text('SET MAIN QUEST'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.yellow,
                  foregroundColor: EverforestColors.bg0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: _addMainQuest,
              ),
          ],
        ),
      );
    }

    final title = _mainQuest['title'] ?? 'Main Quest';
    final progress = _mainQuest['progress'] ?? 0;
    final target = _mainQuest['xp_reward'] ?? 100;
    final progressValue =
        target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.5),
        border:
            Border.all(color: EverforestColors.yellow.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: EverforestColors.yellow.withValues(alpha: 0.05),
              blurRadius: 20)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'MAIN QUEST: $title',
                  style: const TextStyle(
                      color: EverforestColors.yellow,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2),
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$progress / $target Stars',
                    style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  if (widget.isAdmin) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit,
                          color: EverforestColors.grey, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _editMainQuest,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: EverforestColors.bg0,
              valueColor:
                  AlwaysStoppedAnimation<Color>(EverforestColors.yellow),
            ),
          ),
        ],
      ),
    );
  }

  void _editMainQuest() async {
    final titleController = TextEditingController(text: _mainQuest['title']);
    final targetController =
        TextEditingController(text: _mainQuest['xp_reward'].toString());
    final progressController =
        TextEditingController(text: _mainQuest['progress'].toString());

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Edit Main Quest',
            style: TextStyle(color: EverforestColors.fg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Quest Title',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: progressController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Current Progress (Stars)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Target (Stars)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Save',
                style: TextStyle(color: EverforestColors.green)),
            onPressed: () async {
              try {
                final target = int.tryParse(targetController.text) ?? 200;
                final progress = int.tryParse(progressController.text) ?? 0;
                await ApiClient.instance
                    .postDaemon('/api/v1/rpg/quests/update', {
                  'quest_id': _mainQuest['id'],
                  'title': titleController.text,
                  'description': _mainQuest['description'] ?? 'Main Quest',
                  'xp_reward': target,
                  'assigned_users': _mainQuest['assigned_users'] ?? '',
                  'progress': progress,
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Failed to update main quest: $e');
              }
            },
          ),
        ],
      ),
    );

    if (updated == true) {
      _fetchMainQuest();
    }
  }

  void _addMainQuest() async {
    final titleController = TextEditingController();
    final targetController = TextEditingController(text: '200');

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Set Main Quest',
            style: TextStyle(color: EverforestColors.yellow)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Quest Title (e.g. Family Vacation)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.yellow)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Target Stars',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.bg2)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: EverforestColors.yellow)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.yellow,
              foregroundColor: EverforestColors.bg0,
            ),
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              try {
                final target = int.tryParse(targetController.text) ?? 200;
                await ApiClient.instance
                    .postDaemon('/api/v1/rpg/quests/add-main', {
                  'title': titleController.text.trim(),
                  'description': 'Gather $target stars',
                  'xp_reward': target,
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                debugPrint('Failed to create main quest: $e');
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created == true) {
      _fetchMainQuest();
    }
  }
}
