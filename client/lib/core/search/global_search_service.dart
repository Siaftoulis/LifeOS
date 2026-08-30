import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_client.dart';
import '../../global_keys.dart';
import '../../app_module_router.dart';
import '../../presentation/widgets/prayer_book/prayer_reader_screen.dart';
import '../../presentation/widgets/prayer_book/psalter_screen.dart';
import '../../presentation/widgets/prayer_book/scripture_screen.dart';
import '../../presentation/widgets/prayer_book/synaxarion_screen.dart';
import '../../presentation/widgets/prayer_book/liturgical_book_screen.dart';

enum SearchCategory {
  all,
  modules,
  prayers,
  music,
  notes,
  gallery,
  settings,
}

class SearchResultItem {
  final String id;
  final String title;
  final String subtitle;
  final SearchCategory category;
  final String badgeLabel;
  final IconData icon;
  final Color accentColor;
  final void Function(BuildContext context)? onAction;
  final Map<String, dynamic>? rawData;

  const SearchResultItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.badgeLabel,
    required this.icon,
    required this.accentColor,
    this.onAction,
    this.rawData,
  });
}

class GlobalSearchService {
  static final GlobalSearchService instance = GlobalSearchService._internal();
  GlobalSearchService._internal();

  /// Search across all domains with optional category filter
  Future<List<SearchResultItem>> search(
    String query, {
    SearchCategory category = SearchCategory.all,
    BuildContext? context,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return _getDefaultSuggestions(category, context);
    }

    final results = <SearchResultItem>[];

    // 1. Modules / Tabs Search
    if (category == SearchCategory.all || category == SearchCategory.modules) {
      results.addAll(_searchModules(cleanQuery, context));
    }

    // 2. Prayer Book / Services Search
    if (category == SearchCategory.all || category == SearchCategory.prayers) {
      results.addAll(_searchPrayers(cleanQuery, context));
    }

    // 3. Settings & System Actions
    if (category == SearchCategory.all || category == SearchCategory.settings) {
      results.addAll(_searchSettings(cleanQuery, context));
    }

    // 4. Concurrently query remote daemon for Music, Notes, Gallery
    final futures = <Future<List<SearchResultItem>>>[];

    if (category == SearchCategory.all || category == SearchCategory.music) {
      futures.add(_searchMusic(cleanQuery, context));
    }

    if (category == SearchCategory.all || category == SearchCategory.notes) {
      futures.add(_searchNotes(cleanQuery, context));
    }

    if (category == SearchCategory.all || category == SearchCategory.gallery) {
      futures.add(_searchGallery(cleanQuery, context));
    }

    final domainResults = await Future.wait(futures);
    for (final list in domainResults) {
      results.addAll(list);
    }

    return results;
  }

  List<SearchResultItem> _getDefaultSuggestions(SearchCategory category, BuildContext? context) {
    final suggestions = <SearchResultItem>[];

    if (category == SearchCategory.all || category == SearchCategory.modules) {
      suggestions.addAll([
        _createModuleItem(
          id: 'prayer_book',
          title: 'Προσευχητάρι & Τυπικόν',
          subtitle: 'Καθημερινές Ακολουθίες, Ήχοι, Κανόνες, Ψαλτήριον & Γραφές',
          icon: Icons.church_rounded,
          accentColor: const Color(0xFFDBBC7F),
          context: context,
        ),
        _createModuleItem(
          id: 'music_library',
          title: 'Μουσική & Ήχος (Media Hub)',
          subtitle: 'Βιβλιοθήκη κομματιών, Offline Downloads & DSP Equalizer',
          icon: Icons.music_note_rounded,
          accentColor: const Color(0xFF83C092),
          context: context,
        ),
        _createModuleItem(
          id: 'obsidian',
          title: 'Σημειώσεις Zen (Obsidian)',
          subtitle: 'Σύνδεση σημειώσεων, Markdown έγγραφα & Προσωπικό Wiki',
          icon: Icons.edit_note_rounded,
          accentColor: const Color(0xFF7FBBB3),
          context: context,
        ),
        _createModuleItem(
          id: 'photo_video_gallery',
          title: 'Συλλογή Φωτογραφιών & Video',
          subtitle: 'Lossless αποθήκευση, Έξυπνα άλμπουμ & Cloud Vault',
          icon: Icons.photo_library_rounded,
          accentColor: const Color(0xFFE69875),
          context: context,
        ),
      ]);
    }

    if (category == SearchCategory.all || category == SearchCategory.prayers) {
      suggestions.addAll([
        _createPrayerItem(
          id: 'matins',
          title: 'Ακολουθία του Όρθρου',
          subtitle: 'Πλήρης Όρθρος με Εωθινά, Αίνους & Αναστάσιμους Κανόνες',
          icon: Icons.wb_twilight_rounded,
          accentColor: const Color(0xFFDBBC7F),
          context: context,
        ),
        _createPrayerItem(
          id: 'vespers',
          title: 'Ακολουθία του Εσπερινού',
          subtitle: 'Κεκραγάρια, Φῶς ἱλαρόν, Προκείμενον & Απόστιχα Ήχου',
          icon: Icons.nights_stay_rounded,
          accentColor: const Color(0xFFD699B6),
          context: context,
        ),
        _createPrayerItem(
          id: 'paraklesis_small',
          title: 'Μικρός Παρακλητικός Κανών',
          subtitle: '«Ὑγρὰν διοδεύσας...» — Ικετήριος Κανών εις την Παναγίαν',
          icon: Icons.front_hand_rounded,
          accentColor: const Color(0xFF7FBBB3),
          context: context,
        ),
        _createPrayerItem(
          id: 'psalter',
          title: 'Ψαλτήριον του Δαυίδ',
          subtitle: 'Πλήρεις 150 Ψαλμοί κατανεμημένοι σε 20 Καθίσματα',
          icon: Icons.menu_book_rounded,
          accentColor: const Color(0xFFA7C080),
          context: context,
        ),
      ]);
    }

    if (category == SearchCategory.all || category == SearchCategory.settings) {
      suggestions.addAll([
        _createSettingItem(
          id: 'preferences_setting',
          title: 'Ρυθμίσεις Συστήματος',
          subtitle: 'Διαμόρφωση εμφάνισης, λογαριασμού και παραμέτρων LifeOS',
          icon: Icons.settings_rounded,
          accentColor: const Color(0xFFA7C080),
          context: context,
        ),
      ]);
    }

    return suggestions;
  }

  // --- 1. MODULES / TABS REGISTRY & SEARCH ---
  List<SearchResultItem> _searchModules(String q, BuildContext? context) {
    final modules = <Map<String, dynamic>>[
      {
        'id': 'home',
        'title': 'Αρχική Οθόνη (Home)',
        'subtitle': 'Κεντρικό ταμπλό και πλοήγηση συστήματος',
        'keywords': 'home αρχικη κεντρικη dashboard matrix grid',
        'icon': Icons.home_rounded,
        'color': const Color(0xFFA7C080),
      },
      {
        'id': 'prayer_book',
        'title': 'Προσευχητάρι & Τυπικόν',
        'subtitle': 'Ορθόδοξες ακολουθίες, κανόνες, συναξάριον & γραφές',
        'keywords': 'prayer book προσευχηταρι προσευχη ακολουθιες τυπικον ορθρος εσπερινος λειτουργια παναγια ψαλτηρι',
        'icon': Icons.church_rounded,
        'color': const Color(0xFFDBBC7F),
      },
      {
        'id': 'music_library',
        'title': 'Βιβλιοθήκη Μουσικής',
        'subtitle': 'Αναπαραγωγή κομματιών, offline downloads & equalizer',
        'keywords': 'music μουσικη τραγουδια audio mp3 dsp equalizer playlist media',
        'icon': Icons.music_note_rounded,
        'color': const Color(0xFF83C092),
      },
      {
        'id': 'photo_video_gallery',
        'title': 'Συλλογή Φωτογραφιών & Video',
        'subtitle': 'Φωτογραφίες, άλμπουμ & cloud media vault',
        'keywords': 'gallery φωτογραφιες αλμπουμ βιντεο photos videos media vault',
        'icon': Icons.photo_library_rounded,
        'color': const Color(0xFFE69875),
      },
      {
        'id': 'obsidian',
        'title': 'Σημειώσεις Zen (Obsidian Vault)',
        'subtitle': 'Σύνταξη markdown, wiki links και οργάνωση σκέψεων',
        'keywords': 'notes σημειωσεις obsidian zen markdown κειμενα εγγραφα wiki vault',
        'icon': Icons.edit_note_rounded,
        'color': const Color(0xFF7FBBB3),
      },
      {
        'id': 'movie_library',
        'title': 'Ταινίες & Σειρές (Movies)',
        'subtitle': 'Παρακολούθηση ταινιών, watchlist & πληροφορίες TMDb',
        'keywords': 'movies ταινιες σειρες cinema watchlist cinema cinema streaming',
        'icon': Icons.movie_rounded,
        'color': const Color(0xFFE67E80),
      },
      {
        'id': 'finance',
        'title': 'Οικονομική Διαχείριση (Finance)',
        'subtitle': 'Έσοδα, έξοδα, προϋπολογισμός και λογαριασμοί',
        'keywords': 'finance οικονομικα εξοδα εσοδα λογιστικα banking χρηματα budget',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF83C092),
      },
      {
        'id': 'books',
        'title': 'Βιβλιοθήκη Αναγνωσμάτων (Books)',
        'subtitle': 'Ηλεκτρονικά βιβλία, PDF, EPUB & σημειώσεις μελέτης',
        'keywords': 'books βιβλια pdf epub αναγνωση ebooks διαβασμα library',
        'icon': Icons.menu_book_rounded,
        'color': const Color(0xFFDBBC7F),
      },
      {
        'id': 'nexus',
        'title': 'Nexus & Καθημερινές Συνήθειες',
        'subtitle': 'Παρακολούθηση στόχων, συνηθειών και ρουτίνας',
        'keywords': 'nexus habits συνηθειες ρουτινα στοχοι goals tracker',
        'icon': Icons.auto_graph_rounded,
        'color': const Color(0xFF7FBBB3),
      },
      {
        'id': 'chtm',
        'title': 'Εργασίες & Tasks (CHTM)',
        'subtitle': 'Διαχείριση εκκρεμοτήτων, Kanban και todo lists',
        'keywords': 'tasks εργασιες chtm todo kanban εκκρεμοτητες checklist',
        'icon': Icons.check_box_outlined,
        'color': const Color(0xFFE67E80),
      },
      {
        'id': 'quests',
        'title': 'RPG Hub & Quests',
        'subtitle': 'Gamification, πόντοι εμπειρίας, αστέρια & αποστολές',
        'keywords': 'rpg quests level points αστερια ανταμοιβες gamification αποστολες',
        'icon': Icons.military_tech_rounded,
        'color': const Color(0xFFDBBC7F),
      },
      {
        'id': 'flashcards',
        'title': 'Κάρτες Μνήμης (Flashcards)',
        'subtitle': 'Επανάληψη με διαστήματα (SRS) και αποστήθιση',
        'keywords': 'flashcards καρτες anki αποστηθιση επαναληψη μελετη study',
        'icon': Icons.style_rounded,
        'color': const Color(0xFFD699B6),
      },
      {
        'id': 'maps_live_tracking',
        'title': 'Χάρτες & GPS Live Tracking',
        'subtitle': 'Χάρτες διαδρομών, σημεία ενδιαφέροντος και τοποθεσία',
        'keywords': 'maps gps χαρτες τοποθεσιες tracking διαδρομες location',
        'icon': Icons.map_rounded,
        'color': const Color(0xFF83C092),
      },
      {
        'id': 'home_management',
        'title': 'Έξυπνο Σπίτι (Smart Home)',
        'subtitle': 'Έλεγχος συσκευών, φωτισμού και αυτοματισμών',
        'keywords': 'smart home εξυπνο σπιτι συσκευες αυτοματισμοι iot',
        'icon': Icons.home_repair_service_rounded,
        'color': const Color(0xFF7FBBB3),
      },
      {
        'id': 'infra',
        'title': 'Υποδομές & Servers (Infra Hub)',
        'subtitle': 'Διαχείριση διακομιστών, Tailscale mesh και docker containers',
        'keywords': 'infra servers tailscale docker cloud διακομιστες δικτυο vpn',
        'icon': Icons.storage_rounded,
        'color': const Color(0xFFA7C080),
      },
      {
        'id': 'project_infinity',
        'title': 'Project Infinity',
        'subtitle': 'Σχεδιασμός μακροπρόθεσμων έργων και στρατηγικής',
        'keywords': 'infinity projects εργα σχεδιασμος roadmap strategy',
        'icon': Icons.all_inclusive_rounded,
        'color': const Color(0xFFD699B6),
      },
      {
        'id': 'preferences_setting',
        'title': 'Ρυθμίσεις & Προτιμήσεις',
        'subtitle': 'Παραμετροποίηση εμφάνισης, συντομεύσεων & ασφάλειας',
        'keywords': 'settings ρυθμισεις προτιμησεις theme θεμα account ασφαλεια',
        'icon': Icons.settings_rounded,
        'color': const Color(0xFFA7C080),
      },
      {
        'id': 'app_drawer',
        'title': 'Συρτάρι Εφαρμογών (App Drawer)',
        'subtitle': 'Πλήρης λίστα όλων των εγκατεστημένων εφαρμογών',
        'keywords': 'drawer apps εφαρμογες grid launcher συρταρι',
        'icon': Icons.apps_rounded,
        'color': const Color(0xFFDBBC7F),
      },
    ];

    final matched = modules.where((m) {
      final t = (m['title'] as String).toLowerCase();
      final s = (m['subtitle'] as String).toLowerCase();
      final k = (m['keywords'] as String).toLowerCase();
      return t.contains(q) || s.contains(q) || k.contains(q);
    });

    return matched.map((m) {
      return _createModuleItem(
        id: m['id'] as String,
        title: m['title'] as String,
        subtitle: m['subtitle'] as String,
        icon: m['icon'] as IconData,
        accentColor: m['color'] as Color,
        context: context,
      );
    }).toList();
  }

  // --- 2. PRAYER BOOK & LITURGICAL SERVICES SEARCH ---
  List<SearchResultItem> _searchPrayers(String q, BuildContext? context) {
    final prayerServices = <Map<String, dynamic>>[
      {
        'id': 'matins',
        'title': 'Ακολουθία του Όρθρου',
        'subtitle': 'Εξάψαλμος, Θεός Κύριος, Κανόνες 8 Ήχων, Εωθινόν & Αίνοι',
        'keywords': 'ορθρος matins εξαψαλμος κανων αινοι ευαγγελιον πρωι',
        'icon': Icons.wb_twilight_rounded,
      },
      {
        'id': 'vespers',
        'title': 'Ακολουθία του Εσπερινού',
        'subtitle': 'Προοιμιακός, Κεκραγάρια, Φως Ιλαρόν, Προκείμενον & Απόστιχα',
        'keywords': 'εσπερινος vespers κεκραγαρια αποστιχα απογευματινη φως ιλαρον',
        'icon': Icons.nights_stay_rounded,
      },
      {
        'id': 'divine_liturgy',
        'title': 'Θεία Λειτουργία Ιωάννου του Χρυσοστόμου',
        'subtitle': 'Αντίφωνα, Τρισάγιος, Απόστολος, Ευαγγέλιον, Χερουβικόν & Ανάληψις',
        'keywords': 'θεια λειτουργια χρυσοστομου ευχαριστια κοινωνια αποστολος ευαγγελιον liturgy',
        'icon': Icons.church_rounded,
      },
      {
        'id': 'divine_liturgy_basil',
        'title': 'Θεία Λειτουργία Μεγάλου Βασιλείου',
        'subtitle': 'Ευχαί Μεγάλου Βασιλείου, «Ἐπὶ σοὶ χαίρει...» & Αναφορά',
        'keywords': 'θεια λειτουργια μεγαλος βασιλειος αναφορα επι σοι χαιρει liturgy basil',
        'icon': Icons.church_rounded,
      },
      {
        'id': 'paraklesis_small',
        'title': 'Μικρός Παρακλητικός Κανών',
        'subtitle': '«Ὑγρὰν διοδεύσας...» — Παράκλησις εις την Παναγίαν',
        'keywords': 'μικρα παρακληση μικρος παρακλητικος κανων παναγια θεοτοκος υγραν διοδευσας',
        'icon': Icons.front_hand_rounded,
      },
      {
        'id': 'paraklesis_great',
        'title': 'Μέγας Παρακλητικός Κανών',
        'subtitle': '«Ἁρματηλάτην Φαραώ...» — Ποίημα Θεοδώρου Βασιλέως του Δούκα',
        'keywords': 'μεγαλη παρακληση μεγας παρακλητικος κανων παναγια αρματηλατην φαραω',
        'icon': Icons.front_hand_rounded,
      },
      {
        'id': 'midnight_office',
        'title': 'Ακολουθία του Μεσονυκτικού',
        'subtitle': 'Ψαλμός 50, Άμωμος (Ψαλμός 118), Τροπάρια Νυμφίου & Ευχαί',
        'keywords': 'μεσονυκτικον midnight office αμωμος νυμφιος 118 νυκτερινη',
        'icon': Icons.dark_mode_rounded,
      },
      {
        'id': 'hour_first',
        'title': 'Ακολουθία της Πρώτης Ώρας (Α\')',
        'subtitle': 'Ψαλμοί 5, 89, 100 & Ευχή «Χριστὲ τὸ φῶς τὸ ἀληθινόν...»',
        'keywords': 'πρωτη ωρα α ωρα πρωι hour first 5 89 100',
        'icon': Icons.wb_sunny_rounded,
      },
      {
        'id': 'hour_third',
        'title': 'Ακολουθία της Τρίτης Ώρας (Γ\')',
        'subtitle': 'Ψαλμοί 16, 24, 50 & Τροπάριον Αγίου Πνεύματος',
        'keywords': 'τριτη ωρα γ ωρα αγιον πνευμα hour third 16 24 50',
        'icon': Icons.schedule_rounded,
      },
      {
        'id': 'hour_sixth',
        'title': 'Ακολουθία της Έκτης Ώρας (Ϛ\')',
        'subtitle': 'Ψαλμοί 53, 54, 90 & Μνήμη της Σταυρώσεως του Κυρίου',
        'keywords': 'εκτη ωρα ς ωρα σταυρωση μεσημερι hour sixth 53 54 90',
        'icon': Icons.access_time_filled_rounded,
      },
      {
        'id': 'hour_ninth',
        'title': 'Ακολουθία της Ενάτης Ώρας (Θ\')',
        'subtitle': 'Ψαλμοί 83, 84, 85 & Μνήμη του Θανάτου του Κυρίου στον Σταυρό',
        'keywords': 'ενατη ωρα θ ωρα θανατος σταυρος hour ninth 83 84 85',
        'icon': Icons.hourglass_bottom_rounded,
      },
      {
        'id': 'small_compline',
        'title': 'Μικρόν Απόδειπνον',
        'subtitle': 'Βραδινή Ακολουθία — Ψαλμοί 50, 69, 142 & Ευχαί Παναγίας',
        'keywords': 'μικρο αποδειπνο αποδειπνον compline βραδινη',
        'icon': Icons.bedtime_rounded,
      },
      {
        'id': 'great_compline',
        'title': 'Μέγα Απόδειπνον',
        'subtitle': '«Μεθ\' ἡμῶν ὁ Θεός...» & «Κύριε τῶν Δυνάμεων...»',
        'keywords': 'μεγα αποδειπνο μεγαλον αποδειπνον μεθ ημων ο θεος κυριε των δυναμεων',
        'icon': Icons.nightlight_round,
      },
      {
        'id': 'communion_prep',
        'title': 'Ακολουθία της Θείας Μεταλήψεως',
        'subtitle': 'Κανών (Ήχος Β\') και Ευχαί Αγίων Πατέρων προ & μετά τη Θεία Κοινωνία',
        'keywords': 'θεια μεταληψη κοινωνια ευχες κανων μεταληψεως χρυσοστομος βασιλειος',
        'icon': Icons.local_bar_rounded,
      },
      {
        'id': 'akathist_hymn',
        'title': 'Ακάθιστος Ύμνος (Χαιρετισμοί)',
        'subtitle': 'Οι 24 Οίκοι της Θεοτόκου («Τῇ ὑπερμάχῳ στρατηγῷ...»)',
        'keywords': 'ακαθιστος υμνος χαιρετισμοι παναγια τη υπερμαχω 24 οικοι',
        'icon': Icons.auto_stories_rounded,
      },
      {
        'id': 'paraklesis_st_nektarios',
        'title': 'Παράκλησις Αγίου Νεκταρίου',
        'subtitle': 'Ικετήριος Κανών εις τον Άγιον Νεκτάριον Πενταπόλεως',
        'keywords': 'αγιος νεκταριος αιγινα παρακληση ιαματικος θαυματουργος',
        'icon': Icons.person_rounded,
      },
      {
        'id': 'paraklesis_st_paisios',
        'title': 'Παράκλησις Αγίου Παϊσίου',
        'subtitle': 'Ικετήριος Κανών εις τον Όσιον Παΐσιον τον Αγιορείτην',
        'keywords': 'αγιος παισιος αγιορειτης σουρωτη παρακληση οσιος',
        'icon': Icons.person_rounded,
      },
      {
        'id': 'paraklesis_st_fanourios',
        'title': 'Παράκλησις Αγίου Φανουρίου',
        'subtitle': 'Ικετήριος Κανών εις τον Μεγαλομάρτυρα Φανούριον',
        'keywords': 'αγιος φανουριος φανουροπιτα παρακληση μαρτυρας',
        'icon': Icons.person_rounded,
      },
      {
        'id': 'artoklasia',
        'title': 'Ακολουθία Αρτοκλασίας & Λιτής',
        'subtitle': 'Ευλόγησις των άρτων, σίτου, οίνου και ελαίου στις πανηγύρεις',
        'keywords': 'αρτοκλασια λιτη αρτοι ευλογια πανηγυρις εορτη',
        'icon': Icons.bakery_dining_rounded,
      },
      {
        'id': 'psalter',
        'title': 'Ψαλτήριον του Προφήτου Δαυίδ',
        'subtitle': 'Όλοι οι 150 Ψαλμοί χωρισμένοι σε 20 Καθίσματα',
        'keywords': 'ψαλτηριον ψαλμοι δαυιδ 150 καθισματα ψαλμος',
        'icon': Icons.menu_book_rounded,
        'is_psalter': true,
      },
      {
        'id': 'scripture_nt',
        'title': 'Καινή Διαθήκη (27 Βιβλία)',
        'subtitle': '4 Ευαγγέλια, Πράξεις, Επιστολές Αποστόλων & Αποκάλυψις',
        'keywords': 'καινη διαθηκη ευαγγελια ματθαιος μαρκος λουκας ιωαννης πραξεις επιστολες αποκαλυψη',
        'icon': Icons.book_rounded,
        'is_nt': true,
      },
      {
        'id': 'scripture_ot',
        'title': 'Παλαιά Διαθήκη (49 Βιβλία)',
        'subtitle': 'Γένεσις, Προφῆται, Σοφία Σολομῶντος, Ψαλμοί & Ιστορικά',
        'keywords': 'παλαια διαθηκη γενεση εξοδος προφητες σοφια 49',
        'icon': Icons.auto_stories_rounded,
        'is_ot': true,
      },
      {
        'id': 'synaxarion',
        'title': 'Συναξάριον & Εορτολόγιον',
        'subtitle': 'Βίοι Αγίων, Εορτές και Μαρτυρολόγιον για κάθε ημέρα του έτους',
        'keywords': 'συναξαριον εορτολογιο αγιοι βιοι αγιων εορτες ημερολογιο',
        'icon': Icons.calendar_today_rounded,
        'is_synaxarion': true,
      },
      {
        'id': 'octoechos',
        'title': 'Παρακλητική / Οκτώηχος',
        'subtitle': 'Αναστάσιμοι Κανόνες, Ύμνοι και Τροπάρια των 8 Ήχων',
        'keywords': 'οκτωηχος παρακλητικη ηχοι αναστασιμοι κανονες δαμασκηνος',
        'icon': Icons.library_music_rounded,
        'is_book': true,
      },
      {
        'id': 'horologion',
        'title': 'Ωρολόγιον το Μέγα',
        'subtitle': 'Πλήρεις Ακολουθίες του Νυχθημέρου & Απολυτίκια Ενιαυτού',
        'keywords': 'ωρολογιον μεγα ακολουθιες απολυτικια κοντακια',
        'icon': Icons.timer_rounded,
        'is_book': true,
      },
      {
        'id': 'triodion',
        'title': 'Τριώδιον Κατανυκτικόν',
        'subtitle': 'Ύμνοι & Κανόνες από την Κυριακή Τελώνου & Φαρισαίου έως το Μ. Σάββατον',
        'keywords': 'τριωδιον τεσσαρακοστη νηστεια μεγαλη εβδομαδα κατανυξη',
        'icon': Icons.book_rounded,
        'is_book': true,
      },
      {
        'id': 'pentecostarion',
        'title': 'Πεντηκοστάριον Χαρμόσυνον',
        'subtitle': 'Αναστάσιμοι ύμνοι από το Άγιον Πάσχα έως την Κυριακή των Αγίων Πάντων',
        'keywords': 'πεντηκοσταριον πασχα ανασταση αναληψη πεντηκοστη',
        'icon': Icons.wb_sunny_rounded,
        'is_book': true,
      },
      {
        'id': 'menaion',
        'title': 'Μηναία του Ενιαυτού',
        'subtitle': 'Τα 12 Μηναία με όλες τις ακολουθίες των ακινήτων εορτών',
        'keywords': 'μηναια 12 μηνες ακινητες εορτες αγιοι',
        'icon': Icons.calendar_month_rounded,
        'is_book': true,
      },
    ];

    final matched = prayerServices.where((p) {
      final t = (p['title'] as String).toLowerCase();
      final s = (p['subtitle'] as String).toLowerCase();
      final k = (p['keywords'] as String).toLowerCase();
      return t.contains(q) || s.contains(q) || k.contains(q);
    });

    return matched.map((p) {
      final pId = p['id'] as String;
      final title = p['title'] as String;
      final sub = p['subtitle'] as String;
      final icon = p['icon'] as IconData;

      if (p['is_psalter'] == true) {
        return SearchResultItem(
          id: pId,
          title: title,
          subtitle: sub,
          category: SearchCategory.prayers,
          badgeLabel: 'ΨΑΛΤΗΡΙΟΝ',
          icon: icon,
          accentColor: const Color(0xFFA7C080),
          onAction: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const PsalterScreen()));
          },
        );
      }

      if (p['is_nt'] == true) {
        return SearchResultItem(
          id: pId,
          title: title,
          subtitle: sub,
          category: SearchCategory.prayers,
          badgeLabel: 'ΚΑΙΝΗ ΔΙΑΘΗΚΗ',
          icon: icon,
          accentColor: const Color(0xFFDBBC7F),
          onAction: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const ScriptureScreen()));
          },
        );
      }

      if (p['is_ot'] == true) {
        return SearchResultItem(
          id: pId,
          title: title,
          subtitle: sub,
          category: SearchCategory.prayers,
          badgeLabel: 'ΠΑΛΑΙΑ ΔΙΑΘΗΚΗ',
          icon: icon,
          accentColor: const Color(0xFFE69875),
          onAction: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const ScriptureScreen()));
          },
        );
      }

      if (p['is_synaxarion'] == true) {
        return SearchResultItem(
          id: pId,
          title: title,
          subtitle: sub,
          category: SearchCategory.prayers,
          badgeLabel: 'ΣΥΝΑΞΑΡΙΟΝ',
          icon: icon,
          accentColor: const Color(0xFF7FBBB3),
          onAction: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => const SynaxarionScreen()));
          },
        );
      }

      if (p['is_book'] == true) {
        return SearchResultItem(
          id: pId,
          title: title,
          subtitle: sub,
          category: SearchCategory.prayers,
          badgeLabel: 'ΛΕΙΤΟΥΡΓΙΚΟ ΒΙΒΛΙΟ',
          icon: icon,
          accentColor: const Color(0xFFD699B6),
          onAction: (ctx) {
            Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => LiturgicalBookScreen(bookId: pId, bookTitle: title)));
          },
        );
      }

      return _createPrayerItem(
        id: pId,
        title: title,
        subtitle: sub,
        icon: icon,
        accentColor: const Color(0xFFDBBC7F),
        context: context,
      );
    }).toList();
  }

  // --- 3. SETTINGS & SYSTEM COMMANDS SEARCH ---
  List<SearchResultItem> _searchSettings(String q, BuildContext? context) {
    final systemActions = [
      _createSettingItem(
        id: 'preferences_setting',
        title: 'OTA System Updates & Rollback',
        subtitle: 'System Settings • Version Control',
        icon: Icons.system_update_rounded,
        accentColor: const Color(0xFFA7C080),
        context: context,
      ),
      _createSettingItem(
        id: 'preferences_setting',
        title: 'Audiophile DSP Equalizer Settings',
        subtitle: 'Music Library • 10-Band EQ & Spatial Effects',
        icon: Icons.tune_rounded,
        accentColor: const Color(0xFF7FBBB3),
        context: context,
      ),
      _createSettingItem(
        id: 'configurator',
        title: 'Spatial Matrix & App Grid Configurator',
        subtitle: 'Preferences • Configure Home Layout',
        icon: Icons.grid_view_rounded,
        accentColor: const Color(0xFFD699B6),
        context: context,
      ),
    ];

    return systemActions.where((item) {
      return item.title.toLowerCase().contains(q) || item.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  // --- 4. REMOTE DAEMON SEARCH METHODS ---
  Future<List<SearchResultItem>> _searchMusic(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/music/tracks?q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final tracks = (data['tracks'] as List?) ?? (data is List ? data : []);
        for (final t in tracks) {
          final title = t['title'] ?? t['name'] ?? 'Unknown Track';
          final artist = t['artist'] ?? 'Unknown Artist';
          list.add(SearchResultItem(
            id: 'music-${t['id'] ?? title}',
            title: title,
            subtitle: '$artist • Track',
            category: SearchCategory.music,
            badgeLabel: 'ΜΟΥΣΙΚΗ',
            icon: Icons.music_note_rounded,
            accentColor: const Color(0xFF83C092),
            onAction: (ctx) {
              spatialEngineKey.currentState?.navigateToModule('music_library');
            },
            rawData: t is Map<String, dynamic> ? t : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  Future<List<SearchResultItem>> _searchNotes(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/markdown/files?q=$q');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final files = data is List ? data : ((data['files'] as List?) ?? []);
        for (final f in files) {
          final name = f['name'] ?? f['path'] ?? 'Note';
          list.add(SearchResultItem(
            id: 'note-$name',
            title: name.toString().replaceAll('.md', ''),
            subtitle: 'Zen Note • Obsidian Vault',
            category: SearchCategory.notes,
            badgeLabel: 'ΣΗΜΕΙΩΣΗ',
            icon: Icons.description_rounded,
            accentColor: const Color(0xFF7FBBB3),
            onAction: (ctx) {
              spatialEngineKey.currentState?.navigateToModule('obsidian');
            },
            rawData: f is Map<String, dynamic> ? f : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  Future<List<SearchResultItem>> _searchGallery(String q, BuildContext? context) async {
    final list = <SearchResultItem>[];
    try {
      final daemonUrl = ApiClient.instance.daemonUrl;
      final uri = Uri.parse('$daemonUrl/api/v1/gallery/assets?q=$q&limit=20');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final assets = (data['assets'] as List?) ?? [];
        for (final a in assets) {
          final title = a['title'] ?? a['filename'] ?? 'Photo Asset';
          final place = a['place'] ?? '';
          final tags = ((a['tags'] as List?) ?? []).join(', ');
          final sub = place.isNotEmpty ? '$place • $tags' : (tags.isNotEmpty ? tags : 'Gallery Photo');
          list.add(SearchResultItem(
            id: 'gallery-${a['id']}',
            title: title,
            subtitle: sub,
            category: SearchCategory.gallery,
            badgeLabel: 'ΦΩΤΟΓΡΑΦΙΑ',
            icon: Icons.image_rounded,
            accentColor: const Color(0xFFE69875),
            onAction: (ctx) {
              spatialEngineKey.currentState?.navigateToModule('photo_video_gallery');
            },
            rawData: a is Map<String, dynamic> ? a : null,
          ));
        }
      }
    } catch (_) {}
    return list;
  }

  // --- ITEM FACTORY HELPERS ---
  SearchResultItem _createModuleItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    BuildContext? context,
  }) {
    return SearchResultItem(
      id: id,
      title: title,
      subtitle: subtitle,
      category: SearchCategory.modules,
      badgeLabel: 'ΚΑΡΤΕΛΑ / TAB',
      icon: icon,
      accentColor: accentColor,
      onAction: (ctx) {
        final navigated = spatialEngineKey.currentState?.navigateToModule(id) ?? false;
        if (!navigated) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => AppModuleRouter.buildModule(id)));
        }
      },
    );
  }

  SearchResultItem _createPrayerItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    BuildContext? context,
  }) {
    return SearchResultItem(
      id: id,
      title: title,
      subtitle: subtitle,
      category: SearchCategory.prayers,
      badgeLabel: 'ΑΚΟΛΟΥΘΙΑ',
      icon: icon,
      accentColor: accentColor,
      onAction: (ctx) {
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => PrayerReaderScreen(
              serviceId: id,
              serviceTitle: title,
              date: DateTime.now(),
            ),
          ),
        );
      },
    );
  }

  SearchResultItem _createSettingItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    BuildContext? context,
  }) {
    return SearchResultItem(
      id: id,
      title: title,
      subtitle: subtitle,
      category: SearchCategory.settings,
      badgeLabel: 'ΡΥΘΜΙΣΗ',
      icon: icon,
      accentColor: accentColor,
      onAction: (ctx) {
        final navigated = spatialEngineKey.currentState?.navigateToModule(id) ?? false;
        if (!navigated) {
          Navigator.of(ctx).push(MaterialPageRoute(builder: (_) => AppModuleRouter.buildModule(id)));
        }
      },
    );
  }
}
