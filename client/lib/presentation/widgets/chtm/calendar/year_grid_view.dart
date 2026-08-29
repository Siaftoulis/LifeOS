import 'package:flutter/material.dart';
import '../../../../theme/everforest_colors.dart';

class YearGridView extends StatelessWidget {
  const YearGridView({
    super.key,
    required this.currentYear,
    required this.onSelectMonth,
  });

  final int currentYear;
  final ValueChanged<int> onSelectMonth;

  static const List<String> kMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final isCurrentMonth =
            now.month == (index + 1) && now.year == currentYear;
        return GestureDetector(
          onTap: () => onSelectMonth(index + 1),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrentMonth
                  ? EverforestColors.green.withValues(alpha: 0.2)
                  : EverforestColors.bg0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isCurrentMonth
                      ? EverforestColors.green
                      : EverforestColors.bg2),
            ),
            alignment: Alignment.center,
            child: Text(
              kMonths[index],
              style: TextStyle(
                color: isCurrentMonth
                    ? EverforestColors.green
                    : EverforestColors.fg,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
