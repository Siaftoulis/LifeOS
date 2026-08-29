import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';
import 'fasting_calendar_sheet.dart';
import 'komboskini_counter_sheet.dart';
import 'prayer_reader_screen.dart';
import 'prayer_rule_tracker_card.dart';
import 'synaxarion_detail_sheet.dart';

class PrayerBookDashboard extends StatefulWidget {
  const PrayerBookDashboard({super.key});

  @override
  State<PrayerBookDashboard> createState() => _PrayerBookDashboardState();
}

class _PrayerBookDashboardState extends State<PrayerBookDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await PrayerRepository.instance.fetchDailyInfo(_selectedDate);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
    _loadData();
  }

  void _openPrayer(String id, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrayerReaderScreen(
          serviceId: id,
          serviceTitle: title,
          date: _selectedDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EverforestColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '☩',
                style: TextStyle(
                  color: EverforestColors.yellow,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ορθόδοξο Προσευχητάρι',
              style: TextStyle(
                color: EverforestColors.fg,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.touch_app_rounded,
                color: EverforestColors.yellow, size: 22),
            tooltip: 'Ψηφιακό Κομποσχοίνι',
            onPressed: () => KomboskiniCounterSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded,
                color: EverforestColors.green, size: 20),
            tooltip: 'Select Date',
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2035),
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: EverforestColors.yellow,
                      onPrimary: EverforestColors.bg0,
                      surface: EverforestColors.bg1,
                      onSurface: EverforestColors.fg,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: EverforestColors.grey, size: 22),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<DailyLiturgicalInfoModel?>(
        valueListenable: PrayerRepository.instance.dailyInfo,
        builder: (context, info, _) {
          if (_isLoading || info == null) {
            return const Center(
              child: CircularProgressIndicator(color: EverforestColors.yellow),
            );
          }

          final primarySaint =
              info.saints.isNotEmpty ? info.saints[0] : null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Bar with Previous / Next Day Arrows
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg1,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: EverforestColors.grey),
                        onPressed: () => _changeDate(-1),
                      ),
                      Column(
                        children: [
                          Text(
                            info.dateFormatted,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                info.tone,
                                style: const TextStyle(
                                  color: EverforestColors.yellow,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(' • ',
                                  style: TextStyle(
                                      color: EverforestColors.grey)),
                              Text(
                                info.movableCycle.isNotEmpty
                                    ? info.movableCycle
                                    : info.period,
                                style: const TextStyle(
                                  color: EverforestColors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: EverforestColors.grey),
                        onPressed: () => _changeDate(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Fasting Rule Banner Pill (Clickable)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => FastingCalendarSheet.show(context,
                      dailyInfo: info),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: EverforestColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: EverforestColors.green.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.eco_rounded,
                            color: EverforestColors.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Νηστεία: ${info.fasting}',
                            style: const TextStyle(
                              color: EverforestColors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.info_outline_rounded,
                            color: EverforestColors.green, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily Prayer Rule Checklist Card (Κανόνας Προσευχής)
                PrayerRuleTrackerCard(selectedDate: _selectedDate),
                const SizedBox(height: 20),

                // Saint of the Day Hero Card (Συναξαριστής)
                if (primarySaint != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          EverforestColors.bg1,
                          EverforestColors.bg2.withValues(alpha: 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: EverforestColors.yellow.withValues(alpha: 0.3),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: EverforestColors.yellow
                                    .withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.church_rounded,
                                  color: EverforestColors.yellow, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ΕΟΡΤΗ & ΣΥΝΑΞΑΡΙΟΝ',
                                    style: TextStyle(
                                      color: EverforestColors.yellow,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    primarySaint.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: EverforestColors.fg,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (primarySaint.shortLife.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            primarySaint.shortLife,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: EverforestColors.fg,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.auto_stories_rounded,
                                size: 16),
                            label: const Text('Βίος Αγίου & Απολυτίκιον'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EverforestColors.yellow,
                              foregroundColor: EverforestColors.bg0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => SynaxarionDetailSheet.show(
                              context,
                              saint: primarySaint,
                              dateFormatted: info.dateFormatted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Daily Scripture Readings (Αναγνώσματα)
                if (info.readings.isNotEmpty) ...[
                  const Text(
                    'ΑΝΑΓΝΩΣΜΑΤΑ ΤΗΣ ΗΜΕΡΑΣ',
                    style: TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...info.readings.map((r) => _buildReadingCard(r)),
                  const SizedBox(height: 24),
                ],

                // Prayer Services Section Header
                const Text(
                  'ΙΕΡΕΣ ΑΚΟΛΟΥΘΙΕΣ & ΠΡΟΣΕΥΧΗΤΑΡΙ',
                  style: TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Grid of Prayers
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _buildPrayerCard(
                      id: 'morning_prayer',
                      title: 'Πρωινή Προσευχή',
                      subtitle: 'Εξέγερσις εκ του ύπνου',
                      icon: Icons.wb_sunny_rounded,
                      color: EverforestColors.yellow,
                      estMin: 15,
                    ),
                    _buildPrayerCard(
                      id: 'small_compline',
                      title: 'Μικρόν Απόδειπνον',
                      subtitle: 'Προσευχή προ του ύπνου',
                      icon: Icons.nights_stay_rounded,
                      color: EverforestColors.purple,
                      estMin: 20,
                    ),
                    _buildPrayerCard(
                      id: 'vespers',
                      title: 'Εσπερινός',
                      subtitle: 'Εσπερινή Ακολουθία',
                      icon: Icons.brightness_4_rounded,
                      color: EverforestColors.orange,
                      estMin: 25,
                    ),
                    _buildPrayerCard(
                      id: 'akathist_hymn',
                      title: 'Ακάθιστος Ύμνος',
                      subtitle: 'Χαιρετισμοί Παναγίας',
                      icon: Icons.auto_stories_rounded,
                      color: EverforestColors.blue,
                      estMin: 35,
                    ),
                    _buildPrayerCard(
                      id: 'communion_prep',
                      title: 'Θεία Μετάληψις',
                      subtitle: 'Ακολουθία & Προετοιμασία',
                      icon: Icons.bloodtype_rounded,
                      color: EverforestColors.red,
                      estMin: 30,
                    ),
                    _buildPrayerCard(
                      id: 'jesus_prayer',
                      title: 'Προσευχή Ιησού',
                      subtitle: 'Κανόνας Κομποσχοινίου',
                      icon: Icons.touch_app_rounded,
                      color: EverforestColors.green,
                      estMin: 10,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadingCard(ScriptureReadingModel reading) {
    final isGospel = reading.type.contains('Ευαγγέλιον');
    final color =
        isGospel ? EverforestColors.yellow : EverforestColors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reading.type.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  reading.reference,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reading.text,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int estMin,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openPrayer(id, title),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  '$estMin λ.',
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
