import 'package:flutter/material.dart';
import '../../../api_client.dart';
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

  const ScriptureVerseModel({required this.number, required this.text});

  factory ScriptureVerseModel.fromJson(Map<String, dynamic> json) {
    return ScriptureVerseModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      text: json['text']?.toString() ?? '',
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
  bool _isLoading = true;
  bool _isLoadingBook = false;
  String? _error;
  double _fontSize = 17.0;
  bool _isParchment = false;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _chapterKeys = {};
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
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/scripture');
      if (data is Map && data['books'] is List) {
        final list = (data['books'] as List)
            .whereType<Map>()
            .map((b) => ScriptureBookSummary.fromJson(Map<String, dynamic>.from(b)))
            .toList();

        if (mounted) {
          setState(() {
            _books = list;
            _isLoading = false;
          });
          await _loadFullBook(widget.initialBookNumber);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Αδυναμία φόρτωσης Αγίας Γραφής.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFullBook(int bookNum) async {
    setState(() => _isLoadingBook = true);
    _chapterKeys.clear();
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/scripture/book?book=$bookNum');
      if (data is Map) {
        final book = ScriptureFullBookModel.fromJson(Map<String, dynamic>.from(data));
        for (final ch in book.chapters) {
          _chapterKeys[ch.number] = GlobalKey();
        }
        if (mounted) {
          setState(() {
            _activeBook = book;
            _isLoadingBook = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingBook = false);
    }
  }

  void _scrollToChapter(int chapterNum) {
    final key = _chapterKeys[chapterNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  void _showBookSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EverforestColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Επιλογή Βιβλίου (Καινή Διαθήκη)',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.separated(
                  itemCount: _books.length,
                  separatorBuilder: (_, __) => const Divider(color: EverforestColors.bg2, height: 1),
                  itemBuilder: (context, idx) {
                    final b = _books[idx];
                    final isCurrent = _activeBook?.number == b.number;

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? EverforestColors.yellow
                              : EverforestColors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${b.number}',
                          style: TextStyle(
                            color: isCurrent ? EverforestColors.bg0 : EverforestColors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        b.nameGreek,
                        style: TextStyle(
                          color: isCurrent ? EverforestColors.yellow : EverforestColors.fg,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        '${b.chapterCount} Κεφάλαια • ${b.verseCount} Στίχοι',
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                      ),
                      trailing: isCurrent
                          ? const Icon(Icons.check_rounded, color: EverforestColors.yellow, size: 18)
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: EverforestColors.grey),
                      onTap: () {
                        Navigator.pop(ctx);
                        _loadFullBook(b.number);
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
    if (_activeBook == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Κεφάλαια: ${_activeBook!.nameGreek}',
                    style: const TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showBookSelector();
                    },
                    icon: const Icon(Icons.menu_book_rounded, size: 16, color: EverforestColors.yellow),
                    label: const Text('Όλα τα Βιβλία', style: TextStyle(color: EverforestColors.yellow, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _activeBook!.chapters.length,
                  itemBuilder: (context, idx) {
                    final chNum = idx + 1;
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pop(ctx);
                        _scrollToChapter(chNum);
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: EverforestColors.bg0,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: EverforestColors.bg2),
                        ),
                        child: Text(
                          '$chNum',
                          style: const TextStyle(
                            color: EverforestColors.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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

  @override
  Widget build(BuildContext context) {
    final bgColor = _isParchment ? const Color(0xFFF6F0E0) : EverforestColors.bg0;
    final fgColor = _isParchment ? const Color(0xFF2C2518) : EverforestColors.fg;
    final rubricColor = _isParchment ? const Color(0xFF9E2A2B) : const Color(0xFFE67E80);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _isParchment ? const Color(0xFFECE2CB) : EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: fgColor),
          onPressed: () => Navigator.pop(context),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _activeBook?.nameGreek ?? 'Καινή Διαθήκη',
                      style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down_rounded, color: fgColor),
                  ],
                ),
              ),
        actions: [
          IconButton(
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
            icon: Icon(_isParchment ? Icons.dark_mode_rounded : Icons.menu_book_rounded, color: fgColor, size: 20),
            tooltip: 'Εναλλαγή θέματος',
            onPressed: () => setState(() => _isParchment = !_isParchment),
          ),
          IconButton(
            icon: Icon(Icons.text_increase_rounded, color: fgColor, size: 20),
            tooltip: 'Αύξηση γραμματοσειράς',
            onPressed: () {
              if (_fontSize < 28) setState(() => _fontSize += 1.5);
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
      ),
      body: _isLoading || _isLoadingBook
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: EverforestColors.red)))
              : _activeBook == null
                  ? const Center(child: Text('Επιλέξτε ένα βιβλίο.', style: TextStyle(color: EverforestColors.grey)))
                  : Stack(
                      children: [
                        // Continuous Uninterrupted Reading Scroll
                        ListView.builder(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                          itemCount: _activeBook!.chapters.length,
                          itemBuilder: (context, cIdx) {
                            final chapter = _activeBook!.chapters[cIdx];

                            return Container(
                              key: _chapterKeys[chapter.number],
                              margin: const EdgeInsets.only(bottom: 32),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Chapter Header Banner
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: rubricColor.withValues(alpha: _isParchment ? 0.12 : 0.16),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: rubricColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Text(
                                      'ΚΕΦΑΛΑΙΟΝ ${chapter.number}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: rubricColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Chapter Verses formatted continuously
                                  ...chapter.verses.map((verse) {
                                    if (_searchQuery.isNotEmpty &&
                                        !verse.text.toLowerCase().contains(_searchQuery) &&
                                        !verse.number.toString().contains(_searchQuery)) {
                                      return const SizedBox.shrink();
                                    }

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 26,
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '${verse.number}',
                                              style: TextStyle(
                                                color: rubricColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: _fontSize * 0.72,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: SelectableText(
                                              verse.text,
                                              style: TextStyle(
                                                color: fgColor,
                                                fontSize: _fontSize,
                                                height: 1.65,
                                                fontFamily: 'serif',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 10),
                                  Divider(color: EverforestColors.bg2.withValues(alpha: 0.4), height: 1),
                                ],
                              ),
                            );
                          },
                        ),

                        // Floating Bottom Action Pill
                        Positioned(
                          bottom: 18,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Material(
                              elevation: 8,
                              borderRadius: BorderRadius.circular(30),
                              color: EverforestColors.yellow,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: _showChapterSelector,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bookmark_border_rounded, color: EverforestColors.bg0, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Κεφάλαια ${_activeBook!.nameGreek}',
                                        style: const TextStyle(
                                          color: EverforestColors.bg0,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
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
