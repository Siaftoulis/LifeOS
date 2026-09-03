import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../api_client.dart';
import '../../../core/repositories/offline_prayer_data.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

class LiturgicalCalendarScreen extends StatefulWidget {
  const LiturgicalCalendarScreen({super.key});

  @override
  State<LiturgicalCalendarScreen> createState() => _LiturgicalCalendarScreenState();
}

class _LiturgicalCalendarScreenState extends State<LiturgicalCalendarScreen> {
  late DateTime _currentMonth;
  Map<String, dynamic>? _todayInfo;
  Map<String, dynamic>? _monthData;
  bool _loading = true;

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

      final results = await Future.wait([
        _fetchDaily(todayStr),
        _fetchLectionaryMonth(monthStr),
      ]);

      setState(() {
        _todayInfo = results[0];
        _monthData = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>> _fetchDaily(String date) async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/daily?date=$date');
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    final dailyReadings = await OfflinePrayerData.loadDailyReadings(date);
    final fallback = PrayerRepository.instance.getFallbackDailyInfo(DateTime.now());

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

  Future<Map<String, dynamic>> _fetchLectionaryMonth(String month) async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/lectionary/month?month=$month');
      if (data is Map && data['days'] is List && (data['days'] as List).isNotEmpty) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}

    final m = int.tryParse(month) ?? DateTime.now().month;
    return await OfflinePrayerData.loadLectionaryMonth(m);
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
      expandedHeight: 120,
      pinned: true,
      backgroundColor: EverforestColors.bg0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Ημερολόγιο',
          style: TextStyle(
            fontSize: 24,
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

  Widget _buildTodayCard() {
    if (_todayInfo == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: EverforestColors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                _todayInfo!['date_formatted'] ?? '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: EverforestColors.fg,
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
                      style: TextStyle(
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
        Text(
          reference,
          style: const TextStyle(fontSize: 12, color: EverforestColors.fg),
        ),
      ],
    );
  }

  Widget _buildMonthHeader() {
    const monthNames = [
      '', 'Ιανουάριος', 'Φεβρουάριος', 'Μάρτιος', 'Απρίλιος',
      'Μάιος', 'Ιούνιος', 'Ιούλιος', 'Αύγουστος', 'Σεπτέμβριος',
      'Οκτώβριος', 'Νοέμβριος', 'Δεκέμβριος',
    ];

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
          Text(
            '${monthNames[_currentMonth.month]} ${_currentMonth.year}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: EverforestColors.fg,
            ),
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
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

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
            children: ['Δ', 'Τ', 'Τ', 'Π', 'Π', 'Σ', 'Κ'].map((d) {
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
                  return const Expanded(child: SizedBox(height: 40));
                }

                final dateKey = '${_currentMonth.month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                final dayData = _getDayData(dateKey);
                final isToday = _isToday(dayNum);
                final hasFeast = dayData?['has_readings'] == true || dayData?['feast']?.toString().isNotEmpty == true;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => _showDayDetail(dateKey, dayData),
                    child: Container(
                      height: 40,
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
                              fontSize: 14,
                              color: isToday ? EverforestColors.green : EverforestColors.fg,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (hasFeast)
                            Container(
                              width: 4,
                              height: 4,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
            Text(
              dateKey,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: EverforestColors.fg,
              ),
            ),
            if (dayData?['feast']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EverforestColors.bg0,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dayData!['feast'],
                  style: TextStyle(
                    fontSize: 16,
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
                  fontSize: 16,
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
    );
  }

  Widget _buildMonthReadings() {
    final days = _monthData!['days'] as List?;
    if (days == null || days.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final daysWithReadings = days.where((d) => d['has_readings'] == true).toList();
    if (daysWithReadings.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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
            const Text(
              'Αναγνώσματα Μηνός',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: EverforestColors.fg,
              ),
            ),
            const SizedBox(height: 12),
            ...daysWithReadings.map((day) {
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
                          day['date'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: EverforestColors.grey,
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
