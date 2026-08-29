import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';
import 'komboskini_counter_sheet.dart';
import 'prayer_reader_screen.dart';

class PrayerRuleTrackerCard extends StatefulWidget {
  const PrayerRuleTrackerCard({
    super.key,
    required this.selectedDate,
    this.onGospelTap,
  });

  final DateTime selectedDate;
  final VoidCallback? onGospelTap;

  @override
  State<PrayerRuleTrackerCard> createState() => _PrayerRuleTrackerCardState();
}

class _PrayerRuleTrackerCardState extends State<PrayerRuleTrackerCard> {
  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void didUpdateWidget(covariant PrayerRuleTrackerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    await PrayerRepository.instance.fetchRuleStatus(widget.selectedDate);
  }

  Future<void> _toggleItem(PrayerRuleItemModel item) async {
    if (item.completed) return; // already completed

    final res = await PrayerRepository.instance.completeRuleItem(
      item.id,
      date: widget.selectedDate,
    );

    if (res != null && mounted) {
      final pts = res['points_awarded'] ?? item.points;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: EverforestColors.bg1,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: EverforestColors.green),
          ),
          content: Row(
            children: [
              const Icon(Icons.star_rounded,
                  color: EverforestColors.yellow, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ολοκληρώθηκε: ${item.title} (+$pts ⭐ Stars)',
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _openItemAction(PrayerRuleItemModel item) {
    if (item.id == 'jesus_prayer') {
      KomboskiniCounterSheet.show(context);
    } else if (item.id == 'gospel_reading') {
      if (widget.onGospelTap != null) {
        widget.onGospelTap!();
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrayerReaderScreen(
            serviceId: item.id,
            serviceTitle: item.title,
            date: widget.selectedDate,
          ),
        ),
      );
    }
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'book':
        return Icons.menu_book_rounded;
      case 'komboskini':
        return Icons.touch_app_rounded;
      case 'moon':
        return Icons.nights_stay_rounded;
      default:
        return Icons.church_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DailyPrayerRuleStatusModel?>(
      valueListenable: PrayerRepository.instance.ruleStatus,
      builder: (context, status, _) {
        if (status == null) {
          return const SizedBox.shrink();
        }

        final progress = status.totalCount > 0
            ? (status.completedCount / status.totalCount).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: EverforestColors.yellow.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Streak & Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              EverforestColors.orange.withValues(alpha: 0.15),
                        ),
                        child: const Icon(Icons.local_fire_department_rounded,
                            color: EverforestColors.orange, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ΚΑΝΟΝΑΣ ΠΡΟΣΕΥΧΗΣ',
                            style: TextStyle(
                              color: EverforestColors.orange,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Σερί: ${status.streakDays} ${status.streakDays == 1 ? "Ημέρα" : "Ημέρες"}',
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: EverforestColors.yellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            EverforestColors.yellow.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: EverforestColors.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '+${status.totalPointsEarned} ⭐',
                          style: const TextStyle(
                            color: EverforestColors.yellow,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: EverforestColors.bg2,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          EverforestColors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${status.completedCount}/${status.totalCount}',
                    style: const TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Checklist Items
              ...status.items.map((item) {
                final iconData = _getIcon(item.icon);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: item.completed
                        ? EverforestColors.green.withValues(alpha: 0.08)
                        : EverforestColors.bg0.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.completed
                          ? EverforestColors.green.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.completed
                            ? EverforestColors.green.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                      child: Icon(
                        item.completed ? Icons.check_rounded : iconData,
                        color: item.completed
                            ? EverforestColors.green
                            : EverforestColors.grey,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: item.completed
                            ? EverforestColors.fg
                            : EverforestColors.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      item.description,
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 11,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+${item.points} ⭐',
                          style: const TextStyle(
                            color: EverforestColors.yellow,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            item.completed
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: item.completed
                                ? EverforestColors.green
                                : EverforestColors.grey,
                          ),
                          onPressed: () => _toggleItem(item),
                        ),
                      ],
                    ),
                    onTap: () => _openItemAction(item),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
