import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../presentation/widgets/prayer_book/psalter_screen.dart';
import '../../presentation/widgets/prayer_book/scripture_screen.dart';
import '../../presentation/widgets/prayer_book/synaxarion_screen.dart';

class OfflinePrayerData {
  OfflinePrayerData._();

  static List<KathismaModel>? _cachedPsalter;
  static List<ScriptureBookSummary>? _cachedScriptureSummaries;
  static Map<int, ScriptureFullBookModel>? _cachedScriptureBooks;
  static Map<String, dynamic>? _cachedSynaxarionRaw;
  static Map<String, dynamic>? _cachedLectionaryRaw;

  // --------------------------------------------------------------------------
  // 1. PSALTER (Ψαλτήριον)
  // --------------------------------------------------------------------------
  static Future<List<KathismaModel>> loadPsalter() async {
    if (_cachedPsalter != null && _cachedPsalter!.isNotEmpty) {
      return _cachedPsalter!;
    }
    try {
      final jsonStr = await rootBundle.loadString('assets/prayers/psalter.json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final rawList = decoded['kathismata'] as List? ?? [];
      final list = rawList
          .whereType<Map>()
          .map((k) => KathismaModel.fromJson(Map<String, dynamic>.from(k)))
          .toList();
      _cachedPsalter = list;
      return list;
    } catch (e) {
      debugPrint('[OfflinePrayerData] Error loading psalter.json: $e');
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // 2. NEW TESTAMENT / SCRIPTURE (Καινή Διαθήκη)
  // --------------------------------------------------------------------------
  static Future<List<ScriptureBookSummary>> loadScriptureBooks() async {
    if (_cachedScriptureSummaries != null && _cachedScriptureSummaries!.isNotEmpty) {
      return _cachedScriptureSummaries!;
    }
    await _ensureScriptureLoaded();
    return _cachedScriptureSummaries ?? [];
  }

  static Future<ScriptureFullBookModel?> loadScriptureBook(int bookNumber) async {
    await _ensureScriptureLoaded();
    if (_cachedScriptureBooks != null && _cachedScriptureBooks!.containsKey(bookNumber)) {
      return _cachedScriptureBooks![bookNumber];
    }
    return null;
  }

  static Future<void> _ensureScriptureLoaded() async {
    if (_cachedScriptureBooks != null && _cachedScriptureSummaries != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/prayers/nt.json');
      final Map<String, dynamic> decoded = jsonDecode(jsonStr);
      final rawBooks = decoded['books'] as List? ?? [];

      final summaries = <ScriptureBookSummary>[];
      final bookMap = <int, ScriptureFullBookModel>{};

      for (final raw in rawBooks) {
        if (raw is Map) {
          final bookJson = Map<String, dynamic>.from(raw);
          final fullBook = ScriptureFullBookModel.fromJson(bookJson);
          bookMap[fullBook.number] = fullBook;

          int totalVerses = 0;
          for (final ch in fullBook.chapters) {
            totalVerses += ch.verses.length;
          }

          summaries.add(ScriptureBookSummary(
            number: fullBook.number,
            nameGreek: fullBook.nameGreek,
            nameEnglish: fullBook.nameEnglish,
            chapterCount: fullBook.chapters.length,
            verseCount: totalVerses,
          ));
        }
      }

      _cachedScriptureBooks = bookMap;
      _cachedScriptureSummaries = summaries;
    } catch (e) {
      debugPrint('[OfflinePrayerData] Error loading nt.json: $e');
    }
  }

  // --------------------------------------------------------------------------
  // 3. SYNAXARION (Συναξαριστής)
  // --------------------------------------------------------------------------
  static Future<Map<String, DayData>> loadSynaxarionMonth(int month) async {
    try {
      if (_cachedSynaxarionRaw == null) {
        final jsonStr = await rootBundle.loadString('assets/prayers/synaxarion.json');
        _cachedSynaxarionRaw = jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      final rawDays = _cachedSynaxarionRaw?['days'] as Map<String, dynamic>? ?? {};
      final monthPrefix = '${month.toString().padLeft(2, '0')}-';
      final result = <String, DayData>{};

      rawDays.forEach((key, val) {
        if (key.startsWith(monthPrefix) && val is Map) {
          final dayJson = Map<String, dynamic>.from(val);
          final saintsList = (dayJson['saints'] as List? ?? [])
              .whereType<Map>()
              .map((s) => SynaxarionSaint.fromJson(Map<String, dynamic>.from(s)))
              .toList();

          result[key] = DayData(
            date: key,
            feast: dayJson['feast']?.toString() ?? '',
            saints: saintsList,
            saintCount: saintsList.length,
          );
        }
      });

      return result;
    } catch (e) {
      debugPrint('[OfflinePrayerData] Error loading synaxarion.json for month $month: $e');
      return {};
    }
  }

  // --------------------------------------------------------------------------
  // 4. LITURGICAL CALENDAR & LECTIONARY (Ημερολόγιο)
  // --------------------------------------------------------------------------
  static Future<Map<String, dynamic>> loadLectionaryMonth(int month, {bool isOldCalendar = false, int year = 2026}) async {
    try {
      if (_cachedLectionaryRaw == null) {
        final jsonStr = await rootBundle.loadString('assets/prayers/lectionary.json');
        _cachedLectionaryRaw = jsonDecode(jsonStr) as Map<String, dynamic>;
      }

      final readings = _cachedLectionaryRaw?['readings'] as Map<String, dynamic>? ?? {};
      final daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      final maxDay = daysInMonth[(month - 1).clamp(0, 11)];
      final days = <Map<String, dynamic>>[];

      for (int day = 1; day <= maxDay; day++) {
        final dateKey = '${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
        final civilDate = DateTime(year, month, day);
        final liturgicalDate = isOldCalendar ? civilDate.subtract(const Duration(days: 13)) : civilDate;
        final lookupKey = '${liturgicalDate.month.toString().padLeft(2, '0')}-${liturgicalDate.day.toString().padLeft(2, '0')}';

        final d = readings[lookupKey];
        String epistleRef = '';
        String gospelRef = '';
        String feast = '';
        bool hasReadings = false;

        if (d is Map) {
          final ep = d['epistle'];
          final gosp = d['gospel'];
          if (ep is Map) epistleRef = ep['reference']?.toString() ?? '';
          if (gosp is Map) gospelRef = gosp['reference']?.toString() ?? '';
          feast = d['feast']?.toString() ?? '';
          hasReadings = epistleRef.isNotEmpty || gospelRef.isNotEmpty;
        }

        days.add({
          'date': dateKey,
          'lookup_key': lookupKey,
          'julian_day': liturgicalDate.day,
          'julian_month': liturgicalDate.month,
          'feast': feast,
          'epistle_ref': epistleRef,
          'gospel_ref': gospelRef,
          'has_readings': hasReadings,
        });
      }

      return {
        'month': month,
        'is_old_calendar': isOldCalendar,
        'days': days,
      };
    } catch (e) {
      debugPrint('[OfflinePrayerData] Error loading lectionary.json: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> loadDailyReadings(String dateKey, {bool isOldCalendar = false}) async {
    // dateKey: MM-DD or YYYY-MM-DD
    try {
      if (_cachedLectionaryRaw == null) {
        final jsonStr = await rootBundle.loadString('assets/prayers/lectionary.json');
        _cachedLectionaryRaw = jsonDecode(jsonStr) as Map<String, dynamic>;
      }
      final readings = _cachedLectionaryRaw?['readings'] as Map<String, dynamic>? ?? {};

      String lookupKey;
      if (isOldCalendar) {
        DateTime dt;
        if (dateKey.length == 10) {
          dt = DateTime.tryParse(dateKey) ?? DateTime.now();
        } else {
          final parts = dateKey.split('-');
          final m = int.tryParse(parts[0]) ?? DateTime.now().month;
          final d = int.tryParse(parts[1]) ?? DateTime.now().day;
          dt = DateTime(DateTime.now().year, m, d);
        }
        final julianDt = dt.subtract(const Duration(days: 13));
        lookupKey = '${julianDt.month.toString().padLeft(2, '0')}-${julianDt.day.toString().padLeft(2, '0')}';
      } else {
        lookupKey = dateKey.length >= 5 ? dateKey.substring(dateKey.length - 5) : dateKey;
      }

      final d = readings[lookupKey];
      if (d is Map) {
        final map = Map<String, dynamic>.from(d);
        map['lookup_key'] = lookupKey;
        return map;
      }
    } catch (_) {}
    return {};
  }
}
