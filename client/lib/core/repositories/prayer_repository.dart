import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../api_client.dart';
import '../telemetry/telemetry_reporter.dart';
import 'built_in_prayers.dart';

class SaintModel {
  final String name;
  final String title;
  final String shortLife;
  final String fullLife;
  final String apolytikion;
  final String kontakion;
  final String megalynarion;

  SaintModel({
    required this.name,
    this.title = '',
    this.shortLife = '',
    this.fullLife = '',
    this.apolytikion = '',
    this.kontakion = '',
    this.megalynarion = '',
  });

  factory SaintModel.fromJson(Map<String, dynamic> json) {
    return SaintModel(
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      shortLife: json['short_life']?.toString() ?? '',
      fullLife: json['full_life']?.toString() ?? '',
      apolytikion: json['apolytikion']?.toString() ?? '',
      kontakion: json['kontakion']?.toString() ?? '',
      megalynarion: json['megalynarion']?.toString() ?? '',
    );
  }
}

class ScriptureReadingModel {
  final String type;
  final String reference;
  final String text;

  ScriptureReadingModel({
    required this.type,
    required this.reference,
    required this.text,
  });

  factory ScriptureReadingModel.fromJson(Map<String, dynamic> json) {
    return ScriptureReadingModel(
      type: json['type']?.toString() ?? '',
      reference: json['reference']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
    );
  }
}

class KatavasiaModel {
  final String id;
  final String name;
  final String tone;
  final String period;

  KatavasiaModel({
    this.id = '',
    this.name = '',
    this.tone = '',
    this.period = '',
  });

  factory KatavasiaModel.fromJson(Map<String, dynamic> json) {
    return KatavasiaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      tone: json['tone']?.toString() ?? '',
      period: json['period']?.toString() ?? '',
    );
  }
}

class DailyLiturgicalInfoModel {
  final String date;
  final String dateFormatted;
  final String tone;
  final String period;
  final String feastName;
  final String fasting;
  final List<SaintModel> saints;
  final List<ScriptureReadingModel> readings;
  final String movableCycle;
  final KatavasiaModel? katavasies;

  DailyLiturgicalInfoModel({
    required this.date,
    required this.dateFormatted,
    required this.tone,
    required this.period,
    required this.feastName,
    required this.fasting,
    required this.saints,
    required this.readings,
    required this.movableCycle,
    this.katavasies,
  });

  factory DailyLiturgicalInfoModel.fromJson(Map<String, dynamic> json) {
    final rawSaints = json['saints'] as List? ?? [];
    final rawReadings = json['readings'] as List? ?? [];
    final rawKat = json['katavasies'] as Map?;

    return DailyLiturgicalInfoModel(
      date: json['date']?.toString() ?? '',
      dateFormatted: json['date_formatted']?.toString() ?? '',
      tone: json['tone']?.toString() ?? 'Ήχος Α\'',
      period: json['period']?.toString() ?? 'Οκτώηχος',
      feastName: json['feast_name']?.toString() ?? '',
      fasting: json['fasting']?.toString() ?? 'Ανηστεία',
      saints: rawSaints
          .whereType<Map>()
          .map((s) => SaintModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      readings: rawReadings
          .whereType<Map>()
          .map((r) =>
              ScriptureReadingModel.fromJson(Map<String, dynamic>.from(r)))
          .toList(),
      movableCycle: json['movable_cycle']?.toString() ?? '',
      katavasies: rawKat != null
          ? KatavasiaModel.fromJson(Map<String, dynamic>.from(rawKat))
          : null,
    );
  }
}

class PrayerSectionModel {
  final String header;
  final String content;
  final bool isRubric;
  final bool isDynamic;
  final String dynamicType;

  PrayerSectionModel({
    this.header = '',
    required this.content,
    this.isRubric = false,
    this.isDynamic = false,
    this.dynamicType = '',
  });

  factory PrayerSectionModel.fromJson(Map<String, dynamic> json) {
    return PrayerSectionModel(
      header: json['header']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isRubric: json['is_rubric'] == true,
      isDynamic: json['is_dynamic'] == true,
      dynamicType: json['dynamic_type']?.toString() ?? '',
    );
  }
}

class CommemorationOptionModel {
  final int index;
  final String name;
  final String title;

  CommemorationOptionModel({
    required this.index,
    required this.name,
    this.title = '',
  });

  factory CommemorationOptionModel.fromJson(Map<String, dynamic> json) {
    return CommemorationOptionModel(
      index: (json['index'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
    );
  }
}

class PrayerServiceModel {
  final String id;
  final String title;
  final String category;
  final String subtitle;
  final int estimatedMin;
  final List<PrayerSectionModel> sections;
  final List<CommemorationOptionModel> commemorations;
  final int selectedCommemorationIndex;

  PrayerServiceModel({
    required this.id,
    required this.title,
    required this.category,
    this.subtitle = '',
    this.estimatedMin = 10,
    required this.sections,
    this.commemorations = const [],
    this.selectedCommemorationIndex = 0,
  });

  factory PrayerServiceModel.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List? ?? [];
    final rawComms = json['commemorations'] as List? ?? [];
    return PrayerServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      estimatedMin: (json['estimated_min'] as num?)?.toInt() ?? 10,
      selectedCommemorationIndex:
          (json['selected_commemoration_idx'] as num?)?.toInt() ?? 0,
      commemorations: rawComms
          .whereType<Map>()
          .map((c) =>
              CommemorationOptionModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      sections: rawSections
          .whereType<Map>()
          .map((s) =>
              PrayerSectionModel.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}

class PrayerRuleItemModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final bool completed;
  final String completedAt;

  PrayerRuleItemModel({
    required this.id,
    required this.title,
    this.description = '',
    this.icon = 'sun',
    this.points = 20,
    this.completed = false,
    this.completedAt = '',
  });

  factory PrayerRuleItemModel.fromJson(Map<String, dynamic> json) {
    return PrayerRuleItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'sun',
      points: (json['points'] as num?)?.toInt() ?? 20,
      completed: json['completed'] == true,
      completedAt: json['completed_at']?.toString() ?? '',
    );
  }
}

class DailyPrayerRuleStatusModel {
  final String date;
  final List<PrayerRuleItemModel> items;
  final int completedCount;
  final int totalCount;
  final int totalPointsEarned;
  final int streakDays;

  DailyPrayerRuleStatusModel({
    required this.date,
    required this.items,
    required this.completedCount,
    required this.totalCount,
    required this.totalPointsEarned,
    required this.streakDays,
  });

  factory DailyPrayerRuleStatusModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return DailyPrayerRuleStatusModel(
      date: json['date']?.toString() ?? '',
      items: rawItems
          .whereType<Map>()
          .map((i) =>
              PrayerRuleItemModel.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      totalPointsEarned: (json['total_points_earned'] as num?)?.toInt() ?? 0,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
    );
  }
}

class PrayerRepository {
  static final PrayerRepository instance = PrayerRepository._internal();

  PrayerRepository._internal() {
    dailyInfo.value = getFallbackDailyInfo(DateTime.now());
    ruleStatus.value = getFallbackRuleStatus(DateTime.now());
  }

  final ValueNotifier<DailyLiturgicalInfoModel?> dailyInfo =
      ValueNotifier<DailyLiturgicalInfoModel?>(null);

  final ValueNotifier<DailyPrayerRuleStatusModel?> ruleStatus =
      ValueNotifier<DailyPrayerRuleStatusModel?>(null);

  final ValueNotifier<Set<String>> favoriteIds =
      ValueNotifier<Set<String>>({});

  final Map<String, DailyLiturgicalInfoModel> _dailyCache = {};
  final Map<String, DailyPrayerRuleStatusModel> _ruleCache = {};
  final Map<String, PrayerServiceModel> _serviceCache = {};

  DailyLiturgicalInfoModel getFallbackDailyInfo([DateTime? date]) {
    final target = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(target);
    final greekMonths = [
      'Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου', 'Μαΐου', 'Ιουνίου',
      'Ιουλίου', 'Αυγούστου', 'Σεπτεμβρίου', 'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου'
    ];
    final greekDays = [
      'Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο', 'Κυριακή'
    ];
    final dayName = greekDays[target.weekday - 1];
    final monthName = greekMonths[target.month - 1];
    final dateFormatted = '$dayName, ${target.day} $monthName';

    final isWedOrFri = target.weekday == DateTime.wednesday || target.weekday == DateTime.friday;
    final fasting = isWedOrFri ? 'Νηστεία (Κατάλυση οίνου & ελαίου)' : 'Ανηστεία (Εις πάντα)';

    return DailyLiturgicalInfoModel(
      date: dateStr,
      dateFormatted: dateFormatted,
      tone: 'Ήχος Α\'',
      period: 'Οκτώηχος',
      feastName: 'Εκκλησιαστικό Ημερολόγιο',
      fasting: fasting,
      saints: [
        SaintModel(
          name: 'Άγιοι της Ημέρας',
          title: 'Συναξάριον & Εορτολόγιο',
          shortLife: 'Μνήμη των ενδόξων Αγίων και Μαρτύρων της Εκκλησίας.',
        ),
      ],
      readings: [],
      movableCycle: 'Εβδομάδα Ματθαίου/Λουκά',
    );
  }

  DailyPrayerRuleStatusModel getFallbackRuleStatus([DateTime? date]) {
    final target = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(target);
    return DailyPrayerRuleStatusModel(
      date: dateStr,
      items: [
        PrayerRuleItemModel(
          id: 'morning_prayers',
          title: 'Πρωινή Προσευχή',
          description: 'Πρωινή ακολουθία & ευχαριστία',
          icon: 'sun',
          points: 25,
        ),
        PrayerRuleItemModel(
          id: 'gospel_reading',
          title: 'Ανάγνωση Ευαγγελίου',
          description: 'Καθημερινό Ευαγγελικό & Αποστολικό ανάγνωσμα',
          icon: 'book',
          points: 20,
        ),
        PrayerRuleItemModel(
          id: 'jesus_prayer',
          title: 'Κομποσκοίνι (Ευχή του Ιησού)',
          description: '«Κύριε Ιησού Χριστέ, ελέησόν με»',
          icon: 'komboskini',
          points: 30,
        ),
        PrayerRuleItemModel(
          id: 'small_compline',
          title: 'Μικρόν Απόδειπνον',
          description: 'Βραδινή προσευχή & κατάνυξις',
          icon: 'moon',
          points: 25,
        ),
      ],
      completedCount: 0,
      totalCount: 4,
      totalPointsEarned: 0,
      streakDays: 1,
    );
  }

  /// Fetches the liturgical and Synaxarion info for the specified date
  Future<DailyLiturgicalInfoModel> fetchDailyInfo([DateTime? date]) async {
    final target = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(target);

    // Instant cache hit if previously loaded
    if (_dailyCache.containsKey(dateStr)) {
      final cached = _dailyCache[dateStr]!;
      dailyInfo.value = cached;
      return cached;
    }

    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/prayers/daily?date=$dateStr');
      if (res is Map) {
        final info = DailyLiturgicalInfoModel.fromJson(
            Map<String, dynamic>.from(res));
        _dailyCache[dateStr] = info;
        dailyInfo.value = info;
        return info;
      }
    } catch (e) {
      debugPrint('PrayerRepository daily fetch error: $e');
    }

    // Return fallback if fetch fails or is offline
    final fallback = getFallbackDailyInfo(target);
    _dailyCache[dateStr] = fallback;
    dailyInfo.value = fallback;
    return fallback;
  }

  /// Fetches the daily prayer rule checklist and streak
  Future<DailyPrayerRuleStatusModel> fetchRuleStatus([DateTime? date]) async {
    final target = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(target);

    if (_ruleCache.containsKey(dateStr)) {
      final cached = _ruleCache[dateStr]!;
      ruleStatus.value = cached;
      return cached;
    }

    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/prayers/rule/today?date=$dateStr');
      if (res is Map) {
        final status = DailyPrayerRuleStatusModel.fromJson(
            Map<String, dynamic>.from(res));
        _ruleCache[dateStr] = status;
        ruleStatus.value = status;
        return status;
      }
    } catch (e) {
      debugPrint('PrayerRepository rule status fetch error: $e');
    }

    final fallback = getFallbackRuleStatus(target);
    _ruleCache[dateStr] = fallback;
    ruleStatus.value = fallback;
    return fallback;
  }

  /// Complete a prayer rule objective and award RPG star points
  Future<Map<String, dynamic>?> completeRuleItem(String serviceId,
      {int durationSec = 300, DateTime? date}) async {
    try {
      final res = await ApiClient.instance.postDaemon(
        '/api/v1/prayers/rule/complete',
        {'service_id': serviceId, 'duration_sec': durationSec},
      );
      if (res is Map) {
        TelemetryReporter.instance.track(
            'prayers', 'rule_completed', {'service_id': serviceId});
        // Refresh rule status
        await fetchRuleStatus(date);
        return Map<String, dynamic>.from(res);
      }
    } catch (e) {
      debugPrint('PrayerRepository complete rule error: $e');
    }
    return null;
  }

  /// Fetches complete prayer text with dynamically inserted Typikon variables
  Future<PrayerServiceModel?> fetchService(String serviceId,
      [DateTime? date, int saintIdx = 0]) async {
    final target = date ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(target);
    final cacheKey = '$serviceId-$dateStr-$saintIdx';

    if (_serviceCache.containsKey(cacheKey)) {
      return _serviceCache[cacheKey];
    }

    try {
      // Route Psalter/Scripture/Horologion/LiturgicalBook requests to specialized endpoints
      String url;
      if (serviceId.startsWith('psalm_')) {
        url = '/api/v1/prayers/psalter/service?id=$serviceId';
      } else if (serviceId.startsWith('scripture_')) {
        // Format: scripture_BOOK_CHAPTER
        final parts = serviceId.split('_');
        if (parts.length >= 3) {
          url = '/api/v1/prayers/scripture/service?book=${parts[1]}&chapter=${parts[2]}';
        } else {
          url = '/api/v1/prayers/service?id=$serviceId&date=$dateStr&saint_idx=$saintIdx';
        }
      } else if (['great_compline', 'royal_hours', 'midnight_office', 'first_hour', 'third_hour', 'sixth_hour', 'ninth_hour'].contains(serviceId)) {
        url = '/api/v1/prayers/horologion/service?id=$serviceId';
      } else if (serviceId.startsWith('tri_') || serviceId.startsWith('pent_')) {
        // Triodion/Pentecostarion services
        final prefix = serviceId.startsWith('tri_') ? 'tri' : 'pent';
        final realId = serviceId.replaceFirst(RegExp(r'^(tri_|pent_)'), '');
        url = '/api/v1/prayers/${prefix}odion/service?id=$realId';
      } else if (serviceId.startsWith('men_')) {
        // Menaion feast
        final feastId = serviceId.replaceFirst('men_', '');
        url = '/api/v1/prayers/menaion/service?id=$feastId';
      } else if (serviceId.startsWith('oct_')) {
        // Octoechos service - strip oct_ prefix to get the real service ID
        final realId = serviceId.replaceFirst(RegExp(r'^oct_[a-z_]+_'), '');
        url = '/api/v1/prayers/octoechos/service?id=$realId';
      } else if (serviceId.startsWith('tone') && serviceId.contains('_')) {
        // Direct Octoechos service ID (e.g. tone1_vespers)
        url = '/api/v1/prayers/octoechos/service?id=$serviceId';
      } else {
        url = '/api/v1/prayers/service?id=$serviceId&date=$dateStr&saint_idx=$saintIdx';
      }

      final res = await ApiClient.instance.getDaemon(url);
      if (res is Map) {
        TelemetryReporter.instance.track(
            'prayers', 'service_opened', {'service_id': serviceId});
        final serviceModel = PrayerServiceModel.fromJson(Map<String, dynamic>.from(res));
        _serviceCache[cacheKey] = serviceModel;
        return serviceModel;
      }
    } catch (e) {
      debugPrint('PrayerRepository service fetch error: $e');
    }

    // Built-in offline fallback prayer
    final builtIn = BuiltInPrayers.getFallbackService(serviceId, '');
    if (builtIn != null) {
      _serviceCache[cacheKey] = builtIn;
      return builtIn;
    }

    return _serviceCache[cacheKey];
  }

  /// Toggle bookmark for a prayer
  Future<void> toggleFavorite(String serviceId) async {
    final current = Set<String>.from(favoriteIds.value);
    if (current.contains(serviceId)) {
      current.remove(serviceId);
      favoriteIds.value = current;
      try {
        await ApiClient.instance
            .deleteDaemon('/api/v1/prayers/favorites/$serviceId');
      } catch (_) {}
    } else {
      current.add(serviceId);
      favoriteIds.value = current;
      try {
        await ApiClient.instance.postDaemon('/api/v1/prayers/favorites', {
          'service_id': serviceId,
        });
      } catch (_) {}
    }
  }

  bool isFavorite(String serviceId) => favoriteIds.value.contains(serviceId);
}
