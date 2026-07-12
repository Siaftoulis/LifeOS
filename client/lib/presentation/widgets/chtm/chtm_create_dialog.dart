import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/chtm_dao.dart';

class CHTMCreateDialog extends StatefulWidget {
  final ChtmDao dao;
  final DateTime selectedDate;

  const CHTMCreateDialog({
    super.key,
    required this.dao,
    required this.selectedDate,
  });

  @override
  State<CHTMCreateDialog> createState() => _CHTMCreateDialogState();
}

class _CHTMCreateDialogState extends State<CHTMCreateDialog> {
  final _titleController = TextEditingController();
  String _itemType = 'TASK'; // 'TASK', 'HABIT', 'EVENT'
  
  // Event time properties
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _colorCode = '#89B4FA';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    if (_itemType == 'TASK') {
      final dueDate = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        12, // default noon
      );

      await widget.dao.insertTask(UserTasksCompanion.insert(
        id: const Uuid().v4(),
        title: title,
        status: const drift.Value('TODO'),
        baseXp: const drift.Value(10),
        dueDate: drift.Value(dueDate.millisecondsSinceEpoch),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    } else if (_itemType == 'HABIT') {
      await widget.dao.insertHabit(UserHabitsCompanion.insert(
        id: const Uuid().v4(),
        name: title,
        frequencyCron: '0 9 * * *', // Daily at 9am default
        targetStreak: const drift.Value(21),
        baseXp: const drift.Value(10),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    } else if (_itemType == 'EVENT') {
      final start = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final end = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Directly insert to database calendarEvents table using ChtmDao's db instance
      await widget.dao.db.into(widget.dao.db.calendarEvents).insert(CalendarEventsCompanion.insert(
        id: const Uuid().v4(),
        title: title,
        startTime: start.millisecondsSinceEpoch,
        endTime: end.millisecondsSinceEpoch,
        colorCode: drift.Value(_colorCode),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: EverforestColors.bg0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Add Agenda Item', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Selector Dropdown
              DropdownButtonFormField<String>(
                value: _itemType,
                dropdownColor: EverforestColors.bg1,
                decoration: const InputDecoration(
                  labelText: 'Item Type',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                ),
                style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
                items: const [
                  DropdownMenuItem(value: 'TASK', child: Text('Task')),
                  DropdownMenuItem(value: 'HABIT', child: Text('Habit')),
                  DropdownMenuItem(value: 'EVENT', child: Text('Calendar Event')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _itemType = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              // Title Field
              TextField(
                controller: _titleController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: InputDecoration(
                  labelText: _itemType == 'HABIT' ? 'Habit Name' : 'Title',
                  labelStyle: const TextStyle(color: EverforestColors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
              if (_itemType == 'EVENT') ...[
                const SizedBox(height: 24),
                // Start Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Start Time', style: TextStyle(color: EverforestColors.fg)),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: _startTime);
                        if (time != null) setState(() => _startTime = time);
                      },
                      child: Text(
                        _startTime.format(context),
                        style: const TextStyle(color: EverforestColors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                // End Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('End Time', style: TextStyle(color: EverforestColors.fg)),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(context: context, initialTime: _endTime);
                        if (time != null) setState(() => _endTime = time);
                      },
                      child: Text(
                        _endTime.format(context),
                        style: const TextStyle(color: EverforestColors.green, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Color Picker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Label Color', style: TextStyle(color: EverforestColors.fg)),
                    Row(
                      children: [
                        _colorOption('#89B4FA', EverforestColors.blue),
                        _colorOption('#A6E3A1', EverforestColors.green),
                        _colorOption('#F9E2AF', EverforestColors.yellow),
                        _colorOption('#F38BA8', EverforestColors.red),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: EverforestColors.green,
            foregroundColor: EverforestColors.bg0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Widget _colorOption(String code, Color color) {
    final isSelected = _colorCode == code;
    return GestureDetector(
      onTap: () => setState(() => _colorCode = code),
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
}
