import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../theme/everforest_colors.dart';

class SynaxarionScreen extends StatefulWidget {
  const SynaxarionScreen({super.key});

  @override
  State<SynaxarionScreen> createState() => _SynaxarionScreenState();
}

class _SynaxarionScreenState extends State<SynaxarionScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedDay = DateTime.now().day;
  Map<String, DayData> _days = {};
  bool _isLoading = true;
  DayData? _selectedDayData;

  static const _monthNames = [
    '', 'Ιανουάριος', 'Φεβρουάριος', 'Μάρτιος', 'Απρίλιος',
    'Μάιος', 'Ιούνιος', 'Ιούλιος', 'Αύγουστος', 'Σεπτέμβριος',
    'Οκτώβριος', 'Νοέμβριος', 'Δεκέμβριος',
  ];

  @override
  void initState() {
    super.initState();
    _loadMonth(_selectedMonth);
  }

  Future<void> _loadMonth(int month) async {
    setState(() {
      _isLoading = true;
      _selectedMonth = month;
    });

    try {
      final data = await ApiClient.instance
          .getDaemon('/api/v1/prayers/synaxarion/month?month=$month');

      if (data is Map) {
        final days = <String, DayData>{};
        for (final dayJson in data['days'] ?? []) {
          final key = dayJson['date'] ?? '';
          days[key] = DayData.fromJson(dayJson);
        }
        setState(() {
          _days = days;
          _isLoading = false;
          final todayKey = '${month.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}';
          _selectedDayData = days[todayKey];
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Συναξαριστής',
          style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: EverforestColors.yellow)))
          else
            Expanded(
              child: Row(
                children: [
                  SizedBox(width: 280, child: _buildCalendarGrid()),
                  Expanded(child: _buildDayDetail()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      height: 48,
      color: EverforestColors.bg1,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: EverforestColors.fg, size: 20),
            onPressed: _selectedMonth > 1 ? () => _loadMonth(_selectedMonth - 1) : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                _monthNames[_selectedMonth],
                style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: EverforestColors.fg, size: 20),
            onPressed: _selectedMonth < 12 ? () => _loadMonth(_selectedMonth + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(2026, _selectedMonth + 1, 0).day;
    final firstWeekday = DateTime(2026, _selectedMonth, 1).weekday;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: ['Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα', 'Κυ'].map((d) =>
              Expanded(child: Center(child: Text(d, style: const TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.w600)))),
            ).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1.2, crossAxisSpacing: 2, mainAxisSpacing: 2,
            ),
            itemCount: (firstWeekday - 1) + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) return const SizedBox();
              final day = index - (firstWeekday - 1) + 1;
              final key = '${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
              final dayData = _days[key];
              final hasSaints = dayData != null && dayData.saintCount > 0;
              final isSelected = day == _selectedDay;
              final isToday = day == DateTime.now().day && _selectedMonth == DateTime.now().month;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = day;
                    _selectedDayData = dayData;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EverforestColors.yellow.withValues(alpha: 0.2)
                        : isToday
                            ? EverforestColors.green.withValues(alpha: 0.1)
                            : EverforestColors.bg1,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? Border.all(color: EverforestColors.yellow, width: 1.5)
                        : isToday
                            ? Border.all(color: EverforestColors.green.withValues(alpha: 0.3))
                            : null,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$day', style: TextStyle(
                        color: isSelected ? EverforestColors.yellow : EverforestColors.fg,
                        fontSize: 13, fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      )),
                      if (hasSaints)
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: EverforestColors.yellow),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayDetail() {
    final dayData = _selectedDayData;
    if (dayData == null || dayData.saints.isEmpty) {
      return Center(
        child: Text(
          'No saints commemorated',
          style: TextStyle(color: EverforestColors.grey, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: EverforestColors.bg1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_selectedDay} ${_monthNames[_selectedMonth]}',
                style: const TextStyle(color: EverforestColors.yellow, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (dayData.feast.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dayData.feast, style: const TextStyle(color: EverforestColors.fg, fontSize: 13)),
              ],
              const SizedBox(height: 4),
              Text(
                '${dayData.saintCount} saint${dayData.saintCount > 1 ? 's' : ''} commemorated',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: dayData.saints.length,
            itemBuilder: (context, index) => _buildSaintCard(dayData.saints[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSaintCard(SynaxarionSaint saint) {
    final hasLife = saint.fullLife.isNotEmpty || saint.shortLife.isNotEmpty;
    final hasHymns = saint.apolytikion.isNotEmpty || saint.kontakion.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: EverforestColors.bg1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasLife || hasHymns ? () => _showSaintDetail(saint) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EverforestColors.yellow.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.person, color: EverforestColors.yellow, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saint.name,
                          style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        if (saint.title.isNotEmpty)
                          Text(saint.title, style: const TextStyle(color: EverforestColors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  if (hasLife || hasHymns)
                    const Icon(Icons.chevron_right, color: EverforestColors.grey, size: 20),
                ],
              ),
              if (saint.shortLife.isNotEmpty && saint.fullLife.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  saint.shortLife,
                  style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSaintDetail(SynaxarionSaint saint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SaintDetailSheet(saint: saint),
    );
  }
}

class _SaintDetailSheet extends StatelessWidget {
  final SynaxarionSaint saint;
  const _SaintDetailSheet({required this.saint});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: EverforestColors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EverforestColors.yellow.withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.person, color: EverforestColors.yellow, size: 36),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      saint.name,
                      style: const TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (saint.title.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        saint.title,
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (saint.fullLife.isNotEmpty) ...[
                    _buildSection('ΒΙΟΣ & ΣΥΝΑΞΑΡΙΟΝ', saint.fullLife, EverforestColors.green),
                    const SizedBox(height: 16),
                  ] else if (saint.shortLife.isNotEmpty) ...[
                    _buildSection('ΒΙΟΣ & ΣΥΝΑΞΑΡΙΟΝ', saint.shortLife, EverforestColors.green),
                    const SizedBox(height: 16),
                  ],
                  if (saint.apolytikion.isNotEmpty) ...[
                    _buildHymnSection('ΑΠΟΛΥΤΙΚΙΟΝ', saint.apolytikion, EverforestColors.yellow),
                    const SizedBox(height: 16),
                  ],
                  if (saint.kontakion.isNotEmpty) ...[
                    _buildHymnSection('ΚΟΝΤΑΚΙΟΝ', saint.kontakion, EverforestColors.purple),
                    const SizedBox(height: 16),
                  ],
                  if (saint.megalynarion.isNotEmpty)
                    _buildHymnSection('ΜΕΓΑΛΥΝΑΡΙΟΝ', saint.megalynarion, EverforestColors.blue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(color: EverforestColors.fg, fontSize: 15, height: 1.6)),
      ],
    );
  }

  Widget _buildHymnSection(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontStyle: FontStyle.italic, height: 1.6)),
        ],
      ),
    );
  }
}

// Data models
class DayData {
  final String date;
  final String feast;
  final List<SynaxarionSaint> saints;
  final int saintCount;

  DayData({required this.date, required this.feast, required this.saints, required this.saintCount});

  factory DayData.fromJson(Map<String, dynamic> json) {
    return DayData(
      date: json['date'] ?? '',
      feast: json['feast'] ?? '',
      saints: (json['saints'] as List?)?.map((s) => SynaxarionSaint.fromJson(s)).toList() ?? [],
      saintCount: json['saint_count'] ?? 0,
    );
  }
}

class SynaxarionSaint {
  final String name;
  final String title;
  final String shortLife;
  final String fullLife;
  final String apolytikion;
  final String kontakion;
  final String megalynarion;

  SynaxarionSaint({
    required this.name, required this.title, required this.shortLife,
    required this.fullLife, required this.apolytikion, required this.kontakion,
    required this.megalynarion,
  });

  factory SynaxarionSaint.fromJson(Map<String, dynamic> json) {
    return SynaxarionSaint(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      shortLife: json['shortLife'] ?? '',
      fullLife: json['fullLife'] ?? '',
      apolytikion: json['apolytikion'] ?? '',
      kontakion: json['kontakion'] ?? '',
      megalynarion: json['megalynarion'] ?? '',
    );
  }
}
