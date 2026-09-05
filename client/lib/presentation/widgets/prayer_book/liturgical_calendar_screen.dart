import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api_client.dart';
import '../../../core/repositories/offline_prayer_data.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

enum CalendarSystem {
  newCalendar, // Νέο Ημερολόγιο (Αναθεωρημένο Ιουλιανό)
  oldCalendar, // Παλαιό Ημερολόγιο (Ιουλιανό, −13 ημέρες)
}

class LiturgicalCalendarScreen extends StatefulWidget {
  const LiturgicalCalendarScreen({super.key});

  @override
  State<LiturgicalCalendarScreen> createState() => _LiturgicalCalendarScreenState();
}

class _LiturgicalCalendarScreenState extends State<LiturgicalCalendarScreen> {
  late DateTime _currentMonth;
  CalendarSystem _calendarSystem = CalendarSystem.newCalendar;
  Map<String, dynamic>? _todayInfo;
  Map<String, dynamic>? _monthData;
  bool _loading = true;

  static const _monthNames = [
    '', 'Ιανουάριος', 'Φεβρουάριος', 'Μάρτιος', 'Απρίλιος',
    'Μάιος', 'Ιούνιος', 'Ιούλιος', 'Αύγουστος', 'Σεπτέμβριος',
    'Οκτώβριος', 'Νοέμβριος', 'Δεκέμβριος',
  ];

  static const _monthNamesGenitive = [
    '', 'Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου',
    'Μαΐου', 'Ιουνίου', 'Ιουλίου', 'Αυγούστου', 'Σεπτεμβρίου',
    'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου',
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final monthStr = _currentMonth.month.toString();
      final isOld = _calendarSystem == CalendarSystem.oldCalendar;

      final results = await Future.wait([
        _fetchDaily(todayStr, isOldCalendar: isOld),
        _fetchLectionaryMonth(monthStr, isOldCalendar: isOld),
      ]);

      if (mounted) {
        setState(() {
          _todayInfo = results[0];
          _monthData = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _fetchDaily(String date, {required bool isOldCalendar}) async {
    final calParam = isOldCalendar ? '&calendar=old' : '';
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/daily?date=$date$calParam');
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    final dailyReadings = await OfflinePrayerData.loadDailyReadings(date, isOldCalendar: isOldCalendar);
    final fallback = PrayerRepository.instance.getFallbackDailyInfo(DateTime.now(), isOldCalendar);

    final readingsList = <Map<String, String>>[];
    if (dailyReadings['epistle'] is Map && (dailyReadings['epistle']['text'] ?? '').toString().isNotEmpty) {
      readingsList.add({
        'type': 'Απόστολος',
        'reference': dailyReadings['epistle']['reference']?.toString() ?? '',
        'text': dailyReadings['epistle']['text']?.toString() ?? '',
      });
    }
    if (dailyReadings['gospel'] is Map && (dailyReadings['gospel']['text'] ?? '').toString().isNotEmpty) {
      readingsList.add({
        'type': 'Ευαγγέλιον',
        'reference': dailyReadings['gospel']['reference']?.toString() ?? '',
        'text': dailyReadings['gospel']['text']?.toString() ?? '',
      });
    }

    return {
      'date': fallback.date,
      'date_formatted': fallback.dateFormatted,
      'tone': fallback.tone,
      'period': fallback.period,
      'feast_name': (dailyReadings['feast']?.toString().isNotEmpty == true)
          ? dailyReadings['feast']
          : fallback.feastName,
      'fasting': fallback.fasting,
      'readings': readingsList,
      'saints': fallback.saints.map((s) => {'name': s.name, 'title': s.title, 'short_life': s.shortLife}).toList(),
    };
  }

  Future<Map<String, dynamic>> _fetchLectionaryMonth(String month, {required bool isOldCalendar}) async {
    final calParam = isOldCalendar ? '&calendar=old' : '';
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/lectionary/month?month=$month$calParam');
      if (data is Map && data['days'] is List && (data['days'] as List).isNotEmpty) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    final m = int.tryParse(month) ?? DateTime.now().month;
    return await OfflinePrayerData.loadLectionaryMonth(m, isOldCalendar: isOldCalendar, year: _currentMonth.year);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.green))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverToBoxAdapter(child: _buildCalendarModeTabs()),
                SliverToBoxAdapter(child: _buildTodayCard()),
                SliverToBoxAdapter(child: _buildMonthHeader()),
                SliverToBoxAdapter(child: _buildCalendarGrid()),
                if (_monthData != null) _buildMonthReadings(),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 110,
      pinned: true,
      backgroundColor: EverforestColors.bg0,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Εκκλησιαστικό Ημερολόγιο',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: EverforestColors.fg,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [EverforestColors.bg0, EverforestColors.bg1],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarModeTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              title: 'Νέο Ημερολόγιο',
              subtitle: 'Αναθεωρημένο Ιουλιανό',
              selected: _calendarSystem == CalendarSystem.newCalendar,
              onTap: () {
                if (_calendarSystem != CalendarSystem.newCalendar) {
                  setState(() => _calendarSystem = CalendarSystem.newCalendar);
                  _loadData();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTabItem(
              title: 'Παλαιό Ημερολόγιο',
              subtitle: 'Ιουλιανό (−13 ημέρες)',
              selected: _calendarSystem == CalendarSystem.oldCalendar,
              onTap: () {
                if (_calendarSystem != CalendarSystem.oldCalendar) {
                  setState(() => _calendarSystem = CalendarSystem.oldCalendar);
                  _loadData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? EverforestColors.green.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: EverforestColors.green.withValues(alpha: 0.6)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? EverforestColors.green : EverforestColors.fg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? EverforestColors.aqua : EverforestColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayCard() {
    if (_todayInfo == null) return const SizedBox.shrink();

    final isOld = _calendarSystem == CalendarSystem.oldCalendar;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOld
              ? EverforestColors.orange.withValues(alpha: 0.3)
              : EverforestColors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: isOld ? EverforestColors.orange : EverforestColors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _todayInfo!['date_formatted'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EverforestColors.fg,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOld
                      ? EverforestColors.orange.withValues(alpha: 0.15)
                      : EverforestColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isOld
                        ? EverforestColors.orange.withValues(alpha: 0.4)
                        : EverforestColors.green.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  isOld ? 'Παλαιό Ημερ.' : 'Νέο Ημερ.',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: isOld ? EverforestColors.orange : EverforestColors.green,
                  ),
                ),
              ),
            ],
          ),
          if (_todayInfo!['tone']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.music_note, 'Ήχος', _todayInfo!['tone']),
          ],
          if (_todayInfo!['period']?.toString().isNotEmpty == true) ...[
            _buildInfoRow(Icons.book, 'Περίοδος', _todayInfo!['period']),
          ],
          if (_todayInfo!['fasting']?.toString().isNotEmpty == true) ...[
            _buildInfoRow(Icons.restaurant, 'Νηστεία', _todayInfo!['fasting']),
          ],
          if (_todayInfo!['feast_name']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EverforestColors.bg0,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: EverforestColors.yellow, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _todayInfo!['feast_name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: EverforestColors.yellow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_todayInfo!['epistle'] != null || _todayInfo!['gospel'] != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Αναγνώσματα',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: EverforestColors.aqua,
              ),
            ),
            if (_todayInfo!['epistle'] != null) ...[
              const SizedBox(height: 4),
              _buildReadingRow('Α', _todayInfo!['epistle']['reference']),
            ],
            if (_todayInfo!['gospel'] != null) ...[
              const SizedBox(height: 4),
              _buildReadingRow('Ε', _todayInfo!['gospel']['reference']),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: EverforestColors.blue, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: EverforestColors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: EverforestColors.fg),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingRow(String type, String reference) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: type == 'Α' ? EverforestColors.purple : EverforestColors.orange,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              type,
              style: const TextStyle(
                fontSize: 10,
                color: EverforestColors.bg0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            reference,
            style: const TextStyle(fontSize: 12, color: EverforestColors.fg),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final isOld = _calendarSystem == CalendarSystem.oldCalendar;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: EverforestColors.fg),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
              });
              _loadData();
            },
          ),
          Column(
            children: [
              Text(
                '${_monthNames[_currentMonth.month]} ${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: EverforestColors.fg,
                ),
              ),
              Text(
                isOld ? 'Παλαιό Ημερολόγιο (π.ημ.)' : 'Νέο Ημερολόγιο (ν.ημ.)',
                style: TextStyle(
                  fontSize: 11,
                  color: isOld ? EverforestColors.orange : EverforestColors.aqua,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: EverforestColors.fg),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;
    final isOld = _calendarSystem == CalendarSystem.oldCalendar;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: ['Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα', 'Κυ'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EverforestColors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          for (var week = 0; week < 6; week++)
            Row(
              children: List.generate(7, (dayIndex) {
                final dayNum = week * 7 + dayIndex - firstDay + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }

                final dateKey = '${_currentMonth.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                final dayData = _getDayData(dateKey);
                final isToday = _isToday(dayNum);
                final hasFeast = dayData?['has_readings'] == true || dayData?['feast']?.toString().isNotEmpty == true;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _showDayDetail(dateKey, dayData),
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? EverforestColors.green.withValues(alpha: 0.2)
                            : hasFeast
                                ? EverforestColors.yellow.withValues(alpha: 0.1)
                                : null,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(color: EverforestColors.green)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayNum',
                            style: TextStyle(
                              fontSize: isOld ? 13 : 14,
                              color: isToday ? EverforestColors.green : EverforestColors.fg,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isOld && dayData?['julian_day'] != null)
                            Text(
                              '${dayData!['julian_day']}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isToday ? EverforestColors.green : EverforestColors.grey,
                              ),
                            ),
                          if (hasFeast && !isOld)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: const BoxDecoration(
                                color: EverforestColors.yellow,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _getDayData(String dateKey) {
    if (_monthData == null) return null;
    final days = _monthData!['days'] as List?;
    if (days == null) return null;
    try {
      return days.firstWhere((d) => d['date'] == dateKey);
    } catch (_) {
      return null;
    }
  }

  bool _isToday(int day) {
    final now = DateTime.now();
    return _currentMonth.year == now.year &&
        _currentMonth.month == now.month &&
        day == now.day;
  }

  void _showDayDetail(String dateKey, Map<String, dynamic>? dayData) {
    final dayParts = dateKey.split('-');
    final m = int.tryParse(dayParts[0]) ?? _currentMonth.month;
    final d = int.tryParse(dayParts[1]) ?? 1;
    final civilDate = DateTime(_currentMonth.year, m, d);
    final civilDateText = '$d ${_monthNamesGenitive[m]} ${_currentMonth.year}';
    final isOld = _calendarSystem == CalendarSystem.oldCalendar;

    DateTime? julianDate;
    String? julianDateText;
    if (isOld) {
      julianDate = civilDate.subtract(const Duration(days: 13));
      julianDateText = '${julianDate.day} ${_monthNamesGenitive[julianDate.month]} (Παλαιό Ημερολόγιο — π.ημ.)';
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EverforestColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    civilDateText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: EverforestColors.fg,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOld
                          ? EverforestColors.orange.withValues(alpha: 0.15)
                          : EverforestColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOld
                            ? EverforestColors.orange.withValues(alpha: 0.4)
                            : EverforestColors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      isOld ? 'Παλαιό Ημερ.' : 'Νέο Ημερ.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOld ? EverforestColors.orange : EverforestColors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (julianDateText != null) ...[
                const SizedBox(height: 4),
                Text(
                  julianDateText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: EverforestColors.aqua,
                  ),
                ),
              ],
              if (dayData?['feast']?.toString().isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dayData!['feast'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: EverforestColors.yellow,
                    ),
                  ),
                ),
              ],
              if (dayData?['has_readings'] == true) ...[
                const SizedBox(height: 16),
                const Text(
                  'Αναγνώσματα',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: EverforestColors.aqua,
                  ),
                ),
                if (dayData?['epistle_ref']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _buildReadingRow('Α', dayData!['epistle_ref']),
                ],
                if (dayData?['gospel_ref']?.toString().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _buildReadingRow('Ε', dayData!['gospel_ref']),
                ],
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthReadings() {
    final days = _monthData!['days'] as List?;
    if (days == null || days.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final daysWithReadings = days.where((d) => d['has_readings'] == true).toList();
    if (daysWithReadings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final isOld = _calendarSystem == CalendarSystem.oldCalendar;

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOld ? 'Αναγνώσματα Μηνός (Παλαιό Ημερολόγιο)' : 'Αναγνώσματα Μηνός (Νέο Ημερολόγιο)',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: EverforestColors.fg,
              ),
            ),
            const SizedBox(height: 12),
            ...daysWithReadings.map((day) {
              final dateStr = day['date']?.toString() ?? '';
              String dayLabel = dateStr;
              if (isOld && day['julian_day'] != null && day['julian_month'] != null) {
                final jm = day['julian_month'] as int;
                final jd = day['julian_day'] as int;
                final mName = (jm >= 1 && jm <= 12) ? _monthNamesGenitive[jm] : '';
                final shortM = mName.length >= 3 ? mName.substring(0, 3) : mName;
                dayLabel = '$dateStr ($jd $shortM. π.ημ.)';
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EverforestColors.bg0,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dayLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: EverforestColors.aqua,
                          ),
                        ),
                        if (day['feast']?.toString().isNotEmpty == true) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              day['feast'],
                              style: const TextStyle(
                                fontSize: 12,
                                color: EverforestColors.yellow,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (day['epistle_ref']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      _buildReadingRow('Α', day['epistle_ref']),
                    ],
                    if (day['gospel_ref']?.toString().isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      _buildReadingRow('Ε', day['gospel_ref']),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
