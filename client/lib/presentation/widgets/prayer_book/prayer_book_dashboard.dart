import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';
import 'fasting_calendar_sheet.dart';
import 'liturgical_book_screen.dart';
import 'liturgical_calendar_screen.dart';
import 'prayer_reader_screen.dart';
import 'prayer_rule_tracker_card.dart';
import 'psalter_screen.dart';
import 'scripture_screen.dart';
import 'synaxarion_screen.dart';
import 'synaxarion_detail_sheet.dart';

class PrayerBookDashboard extends StatefulWidget {
  const PrayerBookDashboard({super.key});

  @override
  State<PrayerBookDashboard> createState() => _PrayerBookDashboardState();
}

class _PrayerBookDashboardState extends State<PrayerBookDashboard> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String _selectedCategory = 'all';

  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'label': 'Όλα'},
    {'id': 'liturgy', 'label': 'Λειτουργίες'},
    {'id': 'hours', 'label': 'Ακολουθίες & Ώρες'},
    {'id': 'paraklesis', 'label': 'Παρακλήσεις'},
    {'id': 'devotion', 'label': 'Κανόνες & Ευχές'},
    {'id': 'books', 'label': 'Βιβλία & Γραφές'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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
    if (id == 'psalter') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PsalterScreen()),
      );
      return;
    }
    if (id == 'scripture') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScriptureScreen()),
      );
      return;
    }
    if (id == 'synaxarion') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SynaxarionScreen()),
      );
      return;
    }
    if (id == 'calendar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiturgicalCalendarScreen()),
      );
      return;
    }
    if (id == 'euchologion' || id == 'sacraments' || id == 'octoechos' ||
        id == 'triodion' || id == 'pentecostarion' || id == 'menaion') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiturgicalBookScreen(
            bookId: id,
            bookTitle: title,
          ),
        ),
      );
      return;
    }
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
      body: ValueListenableBuilder<DailyLiturgicalInfoModel?>(
        valueListenable: PrayerRepository.instance.dailyInfo,
        builder: (context, info, _) {
          final effectiveInfo = info ??
              PrayerRepository.instance.getFallbackDailyInfo(_selectedDate);
          final primarySaint = effectiveInfo.saints.isNotEmpty
              ? effectiveInfo.saints[0]
              : null;

          return Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final isDesktop = width >= 1080;
                  final isTablet = width >= 680 && width < 1080;

                  if (isDesktop) {
                    // Desktop: 2-column sidebar layout
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 340,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                            child: _buildDailyPanel(
                                effectiveInfo, primarySaint, isDesktop),
                          ),
                        ),
                        Container(
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCategoryChips(),
                                const SizedBox(height: 16),
                                _buildPrayerGrid(columns: 3),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Tablet & Mobile
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                        isTablet ? 20 : 12, 8, isTablet ? 20 : 12, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(effectiveInfo),
                        const SizedBox(height: 10),
                        _buildFastingBanner(effectiveInfo),
                        const SizedBox(height: 12),
                        PrayerRuleTrackerCard(selectedDate: _selectedDate),
                        const SizedBox(height: 14),
                        if (primarySaint != null) ...[
                          _buildSaintCard(primarySaint, effectiveInfo,
                              isCompact: !isTablet),
                          const SizedBox(height: 14),
                        ],
                        if (effectiveInfo.readings.isNotEmpty) ...[
                          _buildReadingsSection(
                              effectiveInfo.readings, isTablet),
                          const SizedBox(height: 16),
                        ],
                        _buildCategoryChips(),
                        const SizedBox(height: 14),
                        _buildPrayerGrid(columns: isTablet ? 3 : 2),
                      ],
                    ),
                  );
                },
              ),
              if (_isLoading)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    color: EverforestColors.yellow,
                    backgroundColor: Colors.transparent,
                    minHeight: 2.5,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDailyPanel(
      DailyLiturgicalInfoModel info, SaintModel? primarySaint, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTopBar(info),
        const SizedBox(height: 10),
        _buildFastingBanner(info),
        const SizedBox(height: 12),
        PrayerRuleTrackerCard(selectedDate: _selectedDate),
        const SizedBox(height: 14),
        if (primarySaint != null) ...[
          _buildSaintCard(primarySaint, info, isCompact: false),
          const SizedBox(height: 14),
        ],
        if (info.readings.isNotEmpty)
          _buildReadingsSection(info.readings, false),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                cat['label']!,
                style: TextStyle(
                  color: isSelected ? EverforestColors.bg0 : EverforestColors.fg,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: EverforestColors.yellow,
              backgroundColor: EverforestColors.bg1,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? EverforestColors.yellow
                      : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              onSelected: (_) {
                setState(() => _selectedCategory = cat['id']!);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopBar(DailyLiturgicalInfoModel info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded,
                color: EverforestColors.grey, size: 22),
            onPressed: () => _changeDate(-1),
            tooltip: 'Προηγούμενη Ημέρα',
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.dateFormatted,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      info.tone,
                      style: const TextStyle(
                        color: EverforestColors.yellow,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(' • ',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 10)),
                    Flexible(
                      child: Text(
                        info.movableCycle.isNotEmpty
                            ? info.movableCycle
                            : info.period,
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (info.katavasies != null && info.katavasies!.name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${info.katavasies!.name} (${info.katavasies!.tone})',
                    style: const TextStyle(
                      color: EverforestColors.aqua,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: EverforestColors.grey, size: 22),
            onPressed: () => _changeDate(1),
            tooltip: 'Επόμενη Ημέρα',
          ),
        ],
      ),
    );
  }

  Widget _buildFastingBanner(DailyLiturgicalInfoModel info) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => FastingCalendarSheet.show(context, dailyInfo: info),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: EverforestColors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: EverforestColors.green.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.eco_rounded,
                color: EverforestColors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Νηστεία: ${info.fasting}',
                style: const TextStyle(
                  color: EverforestColors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.info_outline_rounded,
                color: EverforestColors.green, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSaintCard(SaintModel primarySaint, DailyLiturgicalInfoModel info,
      {required bool isCompact}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EverforestColors.yellow.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EverforestColors.yellow.withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.church_rounded,
                    color: EverforestColors.yellow, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ΕΟΡΤΗ & ΣΥΝΑΞΑΡΙΟΝ',
                      style: TextStyle(
                        color: EverforestColors.yellow,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      primarySaint.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (primarySaint.shortLife.isNotEmpty && !isCompact) ...[
            const SizedBox(height: 8),
            Text(
              primarySaint.shortLife,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: EverforestColors.fg,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => SynaxarionDetailSheet.show(
                context,
                saint: primarySaint,
                dateFormatted: info.dateFormatted,
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EverforestColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: EverforestColors.yellow.withValues(alpha: 0.35),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded,
                        color: EverforestColors.yellow, size: 14),
                    SizedBox(width: 5),
                    Text(
                      'Βίος & Παράκλησις',
                      style: TextStyle(
                        color: EverforestColors.yellow,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingsSection(
      List<ScriptureReadingModel> readings, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ΑΝΑΓΝΩΣΜΑΤΑ ΤΗΣ ΗΜΕΡΑΣ',
          style: TextStyle(
            color: EverforestColors.grey,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        ...readings.map((r) => _buildReadingCard(r)),
      ],
    );
  }

  Widget _buildReadingCard(ScriptureReadingModel reading) {
    final isGospel = reading.type.contains('Ευαγγέλιον');
    final color = isGospel ? EverforestColors.yellow : EverforestColors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  reading.type.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reading.reference,
                  style: const TextStyle(
                    color: EverforestColors.fg,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reading.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerGrid({required int columns}) {
    final allPrayers = [
      _PrayerEntry(
        id: 'divine_liturgy_chrysostom',
        title: 'Θεία Λειτουργία',
        subtitle: 'Ιωάννου Χρυσοστόμου',
        icon: Icons.church_rounded,
        color: EverforestColors.yellow,
        estMin: 75,
        category: 'liturgy',
      ),
      _PrayerEntry(
        id: 'divine_liturgy_basil',
        title: 'Θ. Λειτουργία Μ. Βασιλείου',
        subtitle: 'Αγίου Βασιλείου του Μεγάλου',
        icon: Icons.auto_stories_rounded,
        color: EverforestColors.purple,
        estMin: 85,
        category: 'liturgy',
      ),
      _PrayerEntry(
        id: 'psalter',
        title: 'Ψαλτήριον',
        subtitle: '150 Ψαλμοί του Δαυΐδ',
        icon: Icons.auto_stories_rounded,
        color: EverforestColors.yellow,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'scripture',
        title: 'Καινή Διαθήκη',
        subtitle: '27 Βιβλία Νέου Διαθήκης',
        icon: Icons.menu_book_rounded,
        color: EverforestColors.blue,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'synaxarion',
        title: 'Συναξαριστής',
        subtitle: '4,397 Άγιοι - 366 ημέρες',
        icon: Icons.church_rounded,
        color: EverforestColors.purple,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'calendar',
        title: 'Ημερολόγιο',
        subtitle: 'Λειτουργικό Ημερολόγιο',
        icon: Icons.calendar_month_rounded,
        color: EverforestColors.aqua,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'morning_prayer',
        title: 'Πρωινή Προσευχή',
        subtitle: 'Εξέγερσις εκ του ύπνου',
        icon: Icons.wb_sunny_rounded,
        color: EverforestColors.yellow,
        estMin: 15,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'small_compline',
        title: 'Μικρόν Απόδειπνον',
        subtitle: 'Προσευχή προ του ύπνου',
        icon: Icons.nights_stay_rounded,
        color: EverforestColors.purple,
        estMin: 20,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'vespers',
        title: 'Εσπερινός',
        subtitle: 'Εσπερινή Ακολουθία',
        icon: Icons.brightness_4_rounded,
        color: EverforestColors.orange,
        estMin: 25,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'matins',
        title: 'Όρθρος',
        subtitle: 'Πρωινή Ακολουθία',
        icon: Icons.wb_twilight_rounded,
        color: EverforestColors.yellow,
        estMin: 30,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'great_compline',
        title: 'Μεγάλον Απόδειπνον',
        subtitle: 'Νυχτερινή Ακολουθία',
        icon: Icons.nightlight_round,
        color: EverforestColors.purple,
        estMin: 25,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'royal_hours',
        title: 'Βασιλικαί Ώραι',
        subtitle: '3η, 6η, 9η Ώρα',
        icon: Icons.access_time_rounded,
        color: EverforestColors.green,
        estMin: 20,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'midnight_office',
        title: 'Μεσονυκτικόν',
        subtitle: 'Νυχτερινή Ακολουθία',
        icon: Icons.dark_mode_rounded,
        color: EverforestColors.purple,
        estMin: 15,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'first_hour',
        title: 'Α\' Ώρα',
        subtitle: 'Πρωινή Ώρα',
        icon: Icons.wb_sunny_outlined,
        color: EverforestColors.yellow,
        estMin: 5,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'third_hour',
        title: 'Γ\' Ώρα',
        subtitle: 'Κατάβασις Αγίου Πνεύματος',
        icon: Icons.schedule_rounded,
        color: EverforestColors.green,
        estMin: 5,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'sixth_hour',
        title: 'Ϛ\' Ώρα',
        subtitle: 'Σταυρός του Κυρίου',
        icon: Icons.history_rounded,
        color: EverforestColors.orange,
        estMin: 5,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'ninth_hour',
        title: 'Θ\' Ώρα',
        subtitle: 'Παράκλησις του Θανάτου',
        icon: Icons.schedule,
        color: EverforestColors.blue,
        estMin: 5,
        category: 'hours',
      ),
      _PrayerEntry(
        id: 'akathist_hymn',
        title: 'Ακάθιστος Ύμνος',
        subtitle: 'Χαιρετισμοί Παναγίας',
        icon: Icons.auto_stories_rounded,
        color: EverforestColors.blue,
        estMin: 35,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'paraklesis',
        title: 'Μικρά Παράκλησις',
        subtitle: 'Ικετήριος Κανών Θεοτόκου',
        icon: Icons.front_hand_rounded,
        color: EverforestColors.purple,
        estMin: 25,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'paraklesis_great',
        title: 'Μεγάλη Παράκλησις',
        subtitle: 'Θεοδώρου Βασιλέως του Δούκα',
        icon: Icons.auto_stories_rounded,
        color: EverforestColors.orange,
        estMin: 35,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'paraklesis_st_nektarios',
        title: 'Παράκλησις Αγ. Νεκταρίου',
        subtitle: 'Πενταπόλεως & Αιγίνης',
        icon: Icons.church_rounded,
        color: EverforestColors.yellow,
        estMin: 30,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'paraklesis_st_paisios',
        title: 'Παράκλησις Αγ. Παϊσίου',
        subtitle: 'Οσίου του Αγιορείτου',
        icon: Icons.auto_stories_rounded,
        color: EverforestColors.green,
        estMin: 30,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'paraklesis_st_fanourios',
        title: 'Παράκλησις Αγ. Φανουρίου',
        subtitle: 'Μεγαλομάρτυρος & Φανουρόπιτα',
        icon: Icons.wb_sunny_rounded,
        color: EverforestColors.orange,
        estMin: 25,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'service_artoklasia_litany',
        title: 'Αρτοκλασία & Λιτανεία',
        subtitle: 'Ευλογία Άρτων, Σίτου & Οίνου',
        icon: Icons.celebration_rounded,
        color: EverforestColors.purple,
        estMin: 20,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'paraklesis_generic',
        title: 'Παράκλησις Αγίου Ημέρας',
        subtitle: 'Δυναμικός Κανών Εορταζομένου',
        icon: Icons.person_rounded,
        color: EverforestColors.aqua,
        estMin: 25,
        category: 'paraklesis',
      ),
      _PrayerEntry(
        id: 'communion_prep',
        title: 'Θεία Μετάληψις',
        subtitle: 'Ακολουθία & Προετοιμασία',
        icon: Icons.bloodtype_rounded,
        color: EverforestColors.red,
        estMin: 30,
        category: 'devotion',
      ),
      _PrayerEntry(
        id: 'communion_thanks',
        title: 'Ευχαριστία Μετάληψης',
        subtitle: 'Ευχές μετά την Κοινωνία',
        icon: Icons.volunteer_activism_rounded,
        color: EverforestColors.aqua,
        estMin: 10,
        category: 'devotion',
      ),
      _PrayerEntry(
        id: 'jesus_prayer',
        title: 'Προσευχή Ιησού',
        subtitle: 'Κανόνας Κομποσχοινίου',
        icon: Icons.touch_app_rounded,
        color: EverforestColors.green,
        estMin: 10,
        category: 'devotion',
      ),
      _PrayerEntry(
        id: 'ephraim_prayer',
        title: 'Προσευχή Εφραίμ',
        subtitle: 'Ταπείνωση & Μετάνοια',
        icon: Icons.self_improvement_rounded,
        color: EverforestColors.orange,
        estMin: 5,
        category: 'devotion',
      ),
      _PrayerEntry(
        id: 'table_prayers',
        title: 'Τραπεζικές Ευχές',
        subtitle: 'Προ & Μετά το Γεύμα',
        icon: Icons.restaurant_rounded,
        color: EverforestColors.yellow,
        estMin: 5,
        category: 'devotion',
      ),
      _PrayerEntry(
        id: 'optina_prayer',
        title: 'Ευχή Οπτίνων',
        subtitle: 'Ευχή Γερόντων',
        icon: Icons.elderly_rounded,
        color: EverforestColors.blue,
        estMin: 3,
        category: 'devotion',
      ),
      _PrayerEntry(
        id: 'triodion',
        title: 'Τριώδιον',
        subtitle: 'Μεγάλη Τεσσαρακοστή',
        icon: Icons.menu_book_rounded,
        color: EverforestColors.purple,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'pentecostarion',
        title: 'Πεντηκοστάριον',
        subtitle: 'Πασχαλιακός Κύκλος',
        icon: Icons.auto_stories_rounded,
        color: EverforestColors.aqua,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'menaion',
        title: 'Μηναίον',
        subtitle: '12 Μεγάλες Εορτές',
        icon: Icons.menu_book_rounded,
        color: EverforestColors.yellow,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'euchologion',
        title: 'Ευχολόγιον',
        subtitle: '38 Ευχές Ημερήσιες & Μυστικές',
        icon: Icons.menu_book_rounded,
        color: EverforestColors.orange,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'sacraments',
        title: 'Μυστήρια',
        subtitle: 'Βάπτισμα, Χρίσμα, Γάμος, Ευχέλαιον',
        icon: Icons.local_library_rounded,
        color: EverforestColors.green,
        estMin: 0,
        category: 'books',
      ),
      _PrayerEntry(
        id: 'octoechos',
        title: 'Οκτωήχος',
        subtitle: '8 Τόνοι - Παρακλητική',
        icon: Icons.queue_music_rounded,
        color: EverforestColors.blue,
        estMin: 0,
        category: 'books',
      ),
    ];

    final filtered = _selectedCategory == 'all'
        ? allPrayers
        : allPrayers.where((p) => p.category == _selectedCategory).toList();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: columns >= 3 ? 1.45 : 1.3,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return _buildPrayerCard(
          id: p.id,
          title: p.title,
          subtitle: p.subtitle,
          icon: p.icon,
          color: p.color,
          estMin: p.estMin,
        );
      },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openPrayer(id, title),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
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
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  if (estMin > 0)
                    Text(
                      '$estMin λ.',
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 10.5,
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
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerEntry {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int estMin;
  final String category;

  const _PrayerEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.estMin,
    required this.category,
  });
}
