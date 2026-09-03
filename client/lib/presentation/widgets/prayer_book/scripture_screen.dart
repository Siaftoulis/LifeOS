import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../core/repositories/offline_prayer_data.dart';
import '../../../theme/everforest_colors.dart';

class ScriptureBookSummary {
  final int number;
  final String nameGreek;
  final String nameEnglish;
  final int chapterCount;
  final int verseCount;

  const ScriptureBookSummary({
    required this.number,
    required this.nameGreek,
    required this.nameEnglish,
    required this.chapterCount,
    required this.verseCount,
  });

  factory ScriptureBookSummary.fromJson(Map<String, dynamic> json) {
    return ScriptureBookSummary(
      number: (json['number'] as num?)?.toInt() ?? 1,
      nameGreek: json['nameGreek']?.toString() ?? '',
      nameEnglish: json['nameEnglish']?.toString() ?? '',
      chapterCount: (json['chapter_count'] as num?)?.toInt() ?? 1,
      verseCount: (json['verse_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScriptureVerseModel {
  final int number;
  final String text;
  final String translation;

  const ScriptureVerseModel({
    required this.number,
    required this.text,
    this.translation = '',
  });

  factory ScriptureVerseModel.fromJson(Map<String, dynamic> json) {
    return ScriptureVerseModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      text: json['text']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
    );
  }
}

class ScriptureChapterModel {
  final int number;
  final List<ScriptureVerseModel> verses;

  const ScriptureChapterModel({required this.number, required this.verses});

  factory ScriptureChapterModel.fromJson(Map<String, dynamic> json) {
    final rawVerses = (json['verses'] as List?) ?? [];
    return ScriptureChapterModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      verses: rawVerses
          .whereType<Map>()
          .map((v) => ScriptureVerseModel.fromJson(Map<String, dynamic>.from(v)))
          .toList(),
    );
  }
}

class ScriptureFullBookModel {
  final int number;
  final String nameGreek;
  final String nameEnglish;
  final List<ScriptureChapterModel> chapters;

  const ScriptureFullBookModel({
    required this.number,
    required this.nameGreek,
    required this.nameEnglish,
    required this.chapters,
  });

  factory ScriptureFullBookModel.fromJson(Map<String, dynamic> json) {
    final rawChapters = (json['chapters'] as List?) ?? [];
    return ScriptureFullBookModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      nameGreek: json['nameGreek']?.toString() ?? '',
      nameEnglish: json['nameEnglish']?.toString() ?? '',
      chapters: rawChapters
          .whereType<Map>()
          .map((c) => ScriptureChapterModel.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }
}

class ScriptureScreen extends StatefulWidget {
  const ScriptureScreen({super.key, this.initialBookNumber = 1});
  final int initialBookNumber;

  @override
  State<ScriptureScreen> createState() => _ScriptureScreenState();
}

class _ScriptureScreenState extends State<ScriptureScreen> {
  List<ScriptureBookSummary> _books = [];
  ScriptureFullBookModel? _activeBook;
  int _activeChapterIndex = 0;
  bool _isLoading = true;
  bool _isLoadingBook = false;
  String? _error;
  double _fontSize = 17.5;
  bool _isParchment = false;
  bool _showTranslation = false;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadBooksAndInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBooksAndInitial() async {
    List<ScriptureBookSummary> list = [];
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/scripture');
      if (data is Map && data['books'] is List) {
        list = (data['books'] as List)
            .whereType<Map>()
            .map((b) => ScriptureBookSummary.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      }
    } catch (_) {}

    // Offline fallback from bundled assets
    if (list.isEmpty) {
      list = await OfflinePrayerData.loadScriptureBooks();
    }

    if (mounted && list.isNotEmpty) {
      setState(() {
        _books = list;
        _isLoading = false;
      });
      await _loadFullBook(widget.initialBookNumber, targetChapter: 1);
    } else if (mounted) {
      setState(() {
        _error = 'Αδυναμία φόρτωσης Αγίας Γραφής.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFullBook(int bookNum, {int targetChapter = 1}) async {
    setState(() => _isLoadingBook = true);
    ScriptureFullBookModel? book;
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/scripture/book?book=$bookNum');
      if (data is Map) {
        book = ScriptureFullBookModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}

    // Offline fallback from bundled assets
    if (book == null) {
      book = await OfflinePrayerData.loadScriptureBook(bookNum);
    }

    if (mounted && book != null) {
      final chIdx = (targetChapter - 1).clamp(0, book.chapters.isNotEmpty ? book.chapters.length - 1 : 0);
      setState(() {
        _activeBook = book;
        _activeChapterIndex = chIdx;
        _isLoadingBook = false;
      });
      _resetScroll();
    } else if (mounted) {
      setState(() => _isLoadingBook = false);
    }
  }

  void _resetScroll() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  void _selectChapter(int chapterIndex) {
    if (_activeBook == null) return;
    if (chapterIndex < 0 || chapterIndex >= _activeBook!.chapters.length) return;
    setState(() {
      _activeChapterIndex = chapterIndex;
    });
    _resetScroll();
  }

  void _prevChapter() {
    if (_activeChapterIndex > 0) {
      _selectChapter(_activeChapterIndex - 1);
    }
  }

  void _nextChapter() {
    if (_activeBook != null && _activeChapterIndex < _activeBook!.chapters.length - 1) {
      _selectChapter(_activeChapterIndex + 1);
    }
  }

  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                alignment: Alignment.center,
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EverforestColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Βιβλία της Καινής Διαθήκης',
                      style: TextStyle(
                        color: _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_books.length}',
                      style: TextStyle(color: EverforestColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Divider(color: _isParchment ? Colors.black12 : EverforestColors.bg2),
              Expanded(
                child: ListView.builder(
                  itemCount: _books.length,
                  itemBuilder: (context, idx) {
                    final b = _books[idx];
                    final isSelected = _activeBook?.number == b.number;

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected
                          ? EverforestColors.yellow.withValues(alpha: _isParchment ? 0.25 : 0.15)
                          : null,
                      leading: CircleAvatar(
                        radius: 13,
                        backgroundColor: isSelected
                            ? EverforestColors.yellow
                            : (_isParchment ? const Color(0xFFE5DECC) : EverforestColors.bg2),
                        child: Text(
                          '${b.number}',
                          style: TextStyle(
                            color: isSelected ? EverforestColors.bg0 : EverforestColors.fg,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        b.nameGreek,
                        style: TextStyle(
                          color: isSelected
                              ? EverforestColors.yellow
                              : (_isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${b.chapterCount} κεφάλαια · ${b.verseCount} στίχοι',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 11.5),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: EverforestColors.yellow, size: 18)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        _loadFullBook(b.number, targetChapter: 1);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChapterSelector() {
    if (_activeBook == null || _activeBook!.chapters.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.55,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EverforestColors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Κεφάλαια: ${_activeBook!.nameGreek}',
                    style: TextStyle(
                      color: _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${_activeBook!.chapters.length} κεφάλαια',
                    style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: _activeBook!.chapters.length,
                  itemBuilder: (context, idx) {
                    final chNum = _activeBook!.chapters[idx].number;
                    final isCurrent = idx == _activeChapterIndex;

                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        Navigator.pop(ctx);
                        _selectChapter(idx);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? EverforestColors.yellow
                              : (_isParchment ? const Color(0xFFE8E0CE) : EverforestColors.bg2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCurrent
                                ? EverforestColors.yellow
                                : EverforestColors.grey.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          '$chNum',
                          style: TextStyle(
                            color: isCurrent
                                ? EverforestColors.bg0
                                : (_isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettingsSheet(BuildContext context, Color fgColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fgColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ρυθμίσεις Ανάγνωσης',
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              // Parchment Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Θέμα Περγαμηνής',
                    style: TextStyle(color: fgColor, fontSize: 14),
                  ),
                  Switch.adaptive(
                    value: _isParchment,
                    activeTrackColor: EverforestColors.yellow,
                    onChanged: (v) {
                      setState(() => _isParchment = v);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Font Size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Μέγεθος Γραμματοσειράς',
                    style: TextStyle(color: fgColor, fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded, color: fgColor),
                        onPressed: _fontSize > 13
                            ? () {
                                setState(() => _fontSize -= 1.5);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                      Text(
                        _fontSize.toStringAsFixed(1),
                        style: TextStyle(color: fgColor, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: fgColor),
                        onPressed: _fontSize < 30
                            ? () {
                                setState(() => _fontSize += 1.5);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final bgColor = _isParchment ? const Color(0xFFF9F5EC) : EverforestColors.bg0;
    final fgColor = _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg;
    final rubricColor = _isParchment ? const Color(0xFF9E2A00) : EverforestColors.red;
    final currentChapter = (_activeBook != null && _activeBook!.chapters.isNotEmpty)
        ? _activeBook!.chapters[_activeChapterIndex.clamp(0, _activeBook!.chapters.length - 1)]
        : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: fgColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: fgColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Αναζήτηση στην Καινή Διαθήκη...',
                  hintStyle: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              )
            : InkWell(
                onTap: _showBookSelector,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _activeBook?.nameGreek ?? 'Καινή Διαθήκη',
                              style: TextStyle(
                                color: fgColor,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14.5 : 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (currentChapter != null)
                              Text(
                                'Κεφάλαιο ${currentChapter.number} / ${_activeBook!.chapters.length}',
                                style: TextStyle(
                                  color: EverforestColors.yellow,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, color: fgColor),
                    ],
                  ),
                ),
              ),
        actions: [
          IconButton(
            visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, color: fgColor, size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
          IconButton(
            visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            icon: Icon(
              Icons.translate_rounded,
              color: _showTranslation ? EverforestColors.aqua : fgColor,
              size: 20,
            ),
            tooltip: _showTranslation ? 'Απόκρυψη Μετάφρασης' : 'Εμφάνιση Μετάφρασης (Π. Τρεμπέλα)',
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          if (isMobile)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.tune_rounded, color: fgColor, size: 20),
              tooltip: 'Ρυθμίσεις',
              onPressed: () => _openSettingsSheet(context, fgColor),
            )
          else ...[
            IconButton(
              icon: Icon(_isParchment ? Icons.dark_mode_rounded : Icons.menu_book_rounded, color: fgColor, size: 20),
              tooltip: 'Εναλλαγή θέματος',
              onPressed: () => setState(() => _isParchment = !_isParchment),
            ),
            IconButton(
              icon: Icon(Icons.text_increase_rounded, color: fgColor, size: 20),
              tooltip: 'Αύξηση γραμματοσειράς',
              onPressed: () {
                if (_fontSize < 30) setState(() => _fontSize += 1.5);
              },
            ),
            IconButton(
              icon: Icon(Icons.text_decrease_rounded, color: fgColor, size: 20),
              tooltip: 'Μείωση γραμματοσειράς',
              onPressed: () {
                if (_fontSize > 13) setState(() => _fontSize -= 1.5);
              },
            ),
          ],
        ],
      ),
      body: _isLoading || _isLoadingBook
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: EverforestColors.red)))
              : _activeBook == null || currentChapter == null
                  ? const Center(child: Text('Επιλέξτε ένα βιβλίο.', style: TextStyle(color: EverforestColors.grey)))
                  : Stack(
                      children: [
                        // Smooth Unified SelectionArea Reader View (Zero Nested Scroll Traps)
                        SelectionArea(
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 16 : 28,
                              16,
                              isMobile ? 16 : 28,
                              90,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 760),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Clean Chapter Header (Liturgical Typography)
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                      alignment: Alignment.center,
                                      child: Column(
                                        children: [
                                          Text(
                                            'ΚΕΦΑΛΑΙΟΝ ${currentChapter.number}',
                                            style: TextStyle(
                                              color: rubricColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isMobile ? 15 : 17,
                                              letterSpacing: 1.2,
                                              fontFamily: 'serif',
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            width: 48,
                                            height: 2,
                                            color: rubricColor.withValues(alpha: 0.35),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Verses Rendered Smoothly in Natural Continuous Biblical Layout
                                    ...currentChapter.verses.map((verse) {
                                      if (_searchQuery.isNotEmpty &&
                                          !verse.text.toLowerCase().contains(_searchQuery) &&
                                          !verse.translation.toLowerCase().contains(_searchQuery) &&
                                          !verse.number.toString().contains(_searchQuery)) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Primary Scripture Verse Row
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: rubricColor.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${verse.number}',
                                                    style: TextStyle(
                                                      color: rubricColor,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: (_fontSize * 0.72).clamp(10.0, 13.0),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    verse.text,
                                                    style: TextStyle(
                                                      color: fgColor,
                                                      fontSize: _fontSize,
                                                      height: 1.7,
                                                      fontFamily: 'serif',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Modern Greek Translation (Π. Τρεμπέλα) if toggled
                                            if (_showTranslation && verse.translation.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(left: 20),
                                                padding: const EdgeInsets.fromLTRB(12, 6, 8, 8),
                                                decoration: BoxDecoration(
                                                  color: EverforestColors.aqua.withValues(
                                                    alpha: _isParchment ? 0.07 : 0.09,
                                                  ),
                                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                                                  border: Border(
                                                    left: BorderSide(
                                                      color: EverforestColors.aqua.withValues(alpha: 0.6),
                                                      width: 2.5,
                                                    ),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Row(
                                                      children: [
                                                        Icon(Icons.translate_rounded, size: 10.5, color: EverforestColors.aqua),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'ΕΡΜΗΝΕΙΑ (Π. ΤΡΕΜΠΕΛΑ)',
                                                          style: TextStyle(
                                                            color: EverforestColors.aqua,
                                                            fontSize: 9,
                                                            fontWeight: FontWeight.bold,
                                                            letterSpacing: 0.8,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      verse.translation,
                                                      style: TextStyle(
                                                        color: fgColor.withValues(alpha: 0.9),
                                                        fontSize: _fontSize * 0.9,
                                                        height: 1.55,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    }),

                                    const SizedBox(height: 24),
                                    Divider(color: _isParchment ? Colors.black12 : EverforestColors.bg2),
                                    const SizedBox(height: 16),

                                    // Quick Bottom Navigation between Chapters
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (_activeChapterIndex > 0)
                                          TextButton.icon(
                                            onPressed: _prevChapter,
                                            icon: const Icon(Icons.arrow_back_ios_rounded, size: 13),
                                            label: Text('Κεφάλαιο ${_activeBook!.chapters[_activeChapterIndex - 1].number}'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: EverforestColors.yellow,
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          )
                                        else
                                          const SizedBox.shrink(),
                                        if (_activeChapterIndex < _activeBook!.chapters.length - 1)
                                          ElevatedButton.icon(
                                            onPressed: _nextChapter,
                                            icon: Text('Κεφάλαιο ${_activeBook!.chapters[_activeChapterIndex + 1].number}'),
                                            label: const Icon(Icons.arrow_forward_ios_rounded, size: 13),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: EverforestColors.yellow,
                                              foregroundColor: EverforestColors.bg0,
                                              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Fluid Floating Navigation Bar (Prev / Chapter Picker / Next)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(30),
                              color: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: EverforestColors.yellow.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.chevron_left_rounded),
                                      color: _activeChapterIndex > 0 ? EverforestColors.yellow : EverforestColors.grey.withValues(alpha: 0.3),
                                      onPressed: _activeChapterIndex > 0 ? _prevChapter : null,
                                      tooltip: 'Προηγούμενο Κεφάλαιο',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: _showChapterSelector,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.bookmark_outline_rounded, size: 16, color: EverforestColors.yellow),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Κεφάλαιο ${currentChapter.number} / ${_activeBook!.chapters.length}',
                                              style: TextStyle(
                                                color: _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(Icons.arrow_drop_up_rounded, size: 18, color: EverforestColors.yellow),
                                          ],
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded),
                                      color: _activeChapterIndex < _activeBook!.chapters.length - 1 ? EverforestColors.yellow : EverforestColors.grey.withValues(alpha: 0.3),
                                      onPressed: _activeChapterIndex < _activeBook!.chapters.length - 1 ? _nextChapter : null,
                                      tooltip: 'Επόμενο Κεφάλαιο',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
