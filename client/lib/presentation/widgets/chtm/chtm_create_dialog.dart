import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../theme/everforest_colors.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../core/general_engine/general_engine_client.dart';

class CHTMCreateDialog extends StatefulWidget {
  final DateTime selectedDate;

  const CHTMCreateDialog({
    super.key,
    required this.selectedDate,
  });

  @override
  State<CHTMCreateDialog> createState() => _CHTMCreateDialogState();
}

class _CHTMCreateDialogState extends State<CHTMCreateDialog> {
  final _titleController = TextEditingController();
  final _sharedWithController = TextEditingController();
  final _assignedToController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  String _itemType = 'task'; // 'task', 'habit', 'event'
  String _completionMode = 'ANY'; // 'ANY' (one member completes for all) or 'ALL' (everyone must complete)
  
  // Event time properties
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _colorCode = '#89B4FA';

  @override
  void dispose() {
    _titleController.dispose();
    _sharedWithController.dispose();
    _assignedToController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final sharedWithRaw = _sharedWithController.text.trim();
    final sharedWith = sharedWithRaw.isNotEmpty
        ? sharedWithRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];
        
    final assignedTo = _assignedToController.text.trim().isNotEmpty
        ? _assignedToController.text.trim()
        : null;

    final durationMins = int.tryParse(_durationController.text.trim()) ?? 45;

    if (_itemType == 'task') {
      final dueDate = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        12, // default noon
      );

      final entity = GeneralEngineEntity(
        id: const Uuid().v4(),
        type: 'task',
        creatorId: 'panospds',
        payload: {
          'title': title,
          'status': 'todo',
          'base_xp': 10,
          'due_date': dueDate.toIso8601String(),
          'duration_minutes': durationMins,
          'completion_mode': _completionMode,
        },
        sharedWith: sharedWith,
        assignedTo: assignedTo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await EngineRepository.instance.saveEntity(entity);

    } else if (_itemType == 'habit') {
      final entity = GeneralEngineEntity(
        id: const Uuid().v4(),
        type: 'habit',
        creatorId: 'panospds',
        payload: {
          'name': title,
          'status': 'todo',
          'frequency_cron': '0 9 * * *',
          'target_streak': 21,
          'base_xp': 10,
          'completion_mode': _completionMode,
        },
        sharedWith: sharedWith,
        assignedTo: assignedTo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await EngineRepository.instance.saveEntity(entity);

    } else if (_itemType == 'event') {
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

      final entity = GeneralEngineEntity(
        id: const Uuid().v4(),
        type: 'event',
        creatorId: 'panospds',
        payload: {
          'title': title,
          'start_time': start.toIso8601String(),
          'end_time': end.toIso8601String(),
          'color_code': _colorCode,
        },
        sharedWith: sharedWith,
        assignedTo: assignedTo,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await EngineRepository.instance.saveEntity(entity);
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
                initialValue: _itemType,
                dropdownColor: EverforestColors.bg1,
                decoration: const InputDecoration(
                  labelText: 'Item Type',
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                ),
                style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
                items: const [
                  DropdownMenuItem(value: 'task', child: Text('Task')),
                  DropdownMenuItem(value: 'habit', child: Text('Habit')),
                  DropdownMenuItem(value: 'event', child: Text('Calendar Event')),
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
                  labelText: _itemType == 'habit' ? 'Habit Name' : 'Title',
                  labelStyle: const TextStyle(color: EverforestColors.grey),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              // Shared With Field
              TextField(
                controller: _sharedWithController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Share With (usernames, comma-separated)',
                  hintText: 'e.g. alice, bob',
                  hintStyle: TextStyle(color: EverforestColors.grey),
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              // Assigned To Field
              TextField(
                controller: _assignedToController,
                style: const TextStyle(color: EverforestColors.fg),
                decoration: const InputDecoration(
                  labelText: 'Assign To (username)',
                  hintText: 'e.g. alice',
                  hintStyle: TextStyle(color: EverforestColors.grey),
                  labelStyle: TextStyle(color: EverforestColors.grey),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                ),
              ),
              const SizedBox(height: 12),
              if (_itemType == 'task') ...[
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: EverforestColors.fg),
                  decoration: const InputDecoration(
                    labelText: 'Est. Duration (minutes)',
                    hintText: '45',
                    hintStyle: TextStyle(color: EverforestColors.grey),
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_itemType == 'task' || _itemType == 'habit') ...[
                DropdownButtonFormField<String>(
                  initialValue: _completionMode,
                  dropdownColor: EverforestColors.bg1,
                  decoration: const InputDecoration(
                    labelText: 'Shared Completion Rule',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                  ),
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'ANY', child: Text('Single Completion (Any member completes for all)')),
                    DropdownMenuItem(value: 'ALL', child: Text('Individual Completion (All members must complete)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _completionMode = val);
                  },
                ),
                const SizedBox(height: 12),
              ],
              if (_itemType == 'event') ...[
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
