import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

class FastingCalendarSheet extends StatelessWidget {
  const FastingCalendarSheet({
    super.key,
    required this.dailyInfo,
  });

  final DailyLiturgicalInfoModel dailyInfo;

  static Future<void> show(
    BuildContext context, {
    required DailyLiturgicalInfoModel dailyInfo,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FastingCalendarSheet(dailyInfo: dailyInfo),
    );
  }

  Color _getFastingColor(String rule) {
    if (rule.contains('Ανηστεία')) return EverforestColors.green;
    if (rule.contains('Ιχθύος')) return EverforestColors.blue;
    if (rule.contains('Οίνου')) return EverforestColors.yellow;
    if (rule.contains('Τυρού')) return EverforestColors.orange;
    return EverforestColors.red;
  }

  IconData _getFastingIcon(String rule) {
    if (rule.contains('Ανηστεία')) return Icons.wb_sunny_rounded;
    if (rule.contains('Ιχθύος')) return Icons.set_meal_rounded;
    if (rule.contains('Οίνου')) return Icons.wine_bar_rounded;
    if (rule.contains('Τυρού')) return Icons.egg_rounded;
    return Icons.eco_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final fastingColor = _getFastingColor(dailyInfo.fasting);
    final fastingIcon = _getFastingIcon(dailyInfo.fasting);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ΝΗΣΤΕΙΟΔΡΟΜΙΟΝ',
                    style: TextStyle(
                      color: EverforestColors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ορθόδοξος Κανόνας Νηστείας',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's Fasting Rule Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: fastingColor.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: fastingColor.withValues(alpha: 0.15),
                          ),
                          child: Icon(fastingIcon,
                              color: fastingColor, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Σημερινή Νηστεία',
                                style: TextStyle(
                                  color: EverforestColors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                dailyInfo.fasting,
                                style: TextStyle(
                                  color: fastingColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Fasting Seasons Overview
                  const Text(
                    'ΚΥΡΙΕΣ ΠΕΡΙΟΔΟΙ ΝΗΣΤΕΙΩΝ',
                    style: TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSeasonTile(
                    'Αγία και Μεγάλη Τεσσαρακοστή',
                    'Από Καθαρά Δευτέρα έως το Άγιον Πάσχα (48 ημέρες)',
                    EverforestColors.purple,
                  ),
                  const SizedBox(height: 10),
                  _buildSeasonTile(
                    'Νηστεία του Δεκαπενταυγούστου',
                    '1 Αυγούστου – 14 Αυγούστου (Κοίμησις της Θεοτόκου)',
                    EverforestColors.blue,
                  ),
                  const SizedBox(height: 10),
                  _buildSeasonTile(
                    'Νηστεία των Χριστουγέννων (Σαρανταήμερο)',
                    '15 Νοεμβρίου – 24 Δεκεμβρίου',
                    EverforestColors.yellow,
                  ),
                  const SizedBox(height: 10),
                  _buildSeasonTile(
                    'Νηστεία των Αγίων Αποστόλων',
                    'Από Δευτέρα των Αγίων Πάντων έως 28 Ιουνίου',
                    EverforestColors.green,
                  ),
                  const SizedBox(height: 10),
                  _buildSeasonTile(
                    'Μονοήμερες Αυστηρές Νηστείες',
                    'Ύψωσις Τιμίου Σταυρού (14/9), Αποτομή Προδρόμου (29/8), Παραμονή Θεοφανείων (5/1)',
                    EverforestColors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonTile(String title, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
