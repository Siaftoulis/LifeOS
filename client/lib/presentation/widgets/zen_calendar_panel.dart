import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class ZenCalendarPanel extends StatefulWidget {
  final String vaultPath;
  final ValueChanged<String> onDateSelected;

  const ZenCalendarPanel({
    super.key,
    required this.vaultPath,
    required this.onDateSelected,
  });

  @override
  State<ZenCalendarPanel> createState() => _ZenCalendarPanelState();
}

class _ZenCalendarPanelState extends State<ZenCalendarPanel> {
  DateTime _focusedMonth = DateTime.now();
  final Set<String> _existingDailyDates = {};

  @override
  void initState() {
    super.initState();
    _scanDailyNotes();
  }

  void _scanDailyNotes() {
    final dailyDir = Directory('${widget.vaultPath}/Daily');
    final Set<String> dates = {};

    if (dailyDir.existsSync()) {
      final files = dailyDir.listSync();
      for (final file in files) {
        if (file is File && file.path.endsWith('.md')) {
          final basename = file.uri.pathSegments.last.replaceAll('.md', '');
          if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(basename)) {
            dates.add(basename);
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _existingDailyDates.clear();
        _existingDailyDates.addAll(dates);
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
      _scanDailyNotes();
    });
  }

  String _formatDateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingEmpty = firstWeekday - 1;

    final today = DateTime.now();
    final todayKey = _formatDateKey(today);

    return Container(
      color: EverforestColors.bg1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: EverforestColors.grey, size: 20),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: EverforestColors.grey, size: 20),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: EverforestColors.bg2),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('M', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('T', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('W', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('T', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('F', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('S', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                Text('S', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: leadingEmpty + daysInMonth,
              itemBuilder: (context, index) {
                if (index < leadingEmpty) {
                  return const SizedBox.shrink();
                }

                final dayNum = index - leadingEmpty + 1;
                final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
                final dateKey = _formatDateKey(date);
                final hasNote = _existingDailyDates.contains(dateKey);
                final isToday = dateKey == todayKey;

                return InkWell(
                  onTap: () {
                    final notePath = '${widget.vaultPath}/Daily/$dateKey.md';
                    widget.onDateSelected(notePath);
                    _scanDailyNotes();
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? EverforestColors.green.withValues(alpha: 0.2)
                          : (hasNote ? EverforestColors.bg2 : Colors.transparent),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isToday ? EverforestColors.green : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            color: isToday
                                ? EverforestColors.green
                                : (hasNote ? EverforestColors.fg : EverforestColors.grey),
                            fontSize: 12,
                            fontWeight: isToday || hasNote ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (hasNote)
                          Positioned(
                            bottom: 3,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: EverforestColors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
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
    );
  }
}
