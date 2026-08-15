import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../../api_client.dart';

class AddQuestDialog extends StatefulWidget {
  final VoidCallback onQuestAdded;

  const AddQuestDialog({super.key, required this.onQuestAdded});

  @override
  State<AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends State<AddQuestDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assignedUsersController = TextEditingController();
  double _xpReward = 50;
  bool _isLoading = false;
  DateTime _dueDate = DateTime.now();

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      await ApiClient.instance.postDaemon('/api/v1/rpg/quests/add', {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'xp_reward': _xpReward.toInt(),
        'assigned_users': _assignedUsersController.text.trim(),
        'due_date': _dueDate.toIso8601String().substring(0, 10),
      });
      if (mounted) {
        widget.onQuestAdded();
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Failed to add quest: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _assignedUsersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EverforestColors.bg0,
      title: const Text('Add Custom Quest', style: TextStyle(color: EverforestColors.fg)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Quest Title',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _assignedUsersController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Assigned Users (e.g. panospds:50, user2:50)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
              ),
            ),
            const SizedBox(height: 32),
            const Text('XP Reward', style: TextStyle(color: EverforestColors.fg)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _xpReward,
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: EverforestColors.green,
                    inactiveColor: EverforestColors.bg1,
                    onChanged: (val) {
                      setState(() => _xpReward = val);
                    },
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text('${_xpReward.toInt()} XP', style: const TextStyle(color: EverforestColors.yellow, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Due Date', style: TextStyle(color: EverforestColors.fg)),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: Text(
                    '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}',
                    style: const TextStyle(color: EverforestColors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Family bounty: anyone can claim it from the quest board. '
              'Cancelling after claiming costs half the reward in stars.',
              style: TextStyle(color: EverforestColors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: EverforestColors.green,
            foregroundColor: EverforestColors.bg0,
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.bg0))
              : const Text('Add Quest'),
        ),
      ],
    );
  }
}
