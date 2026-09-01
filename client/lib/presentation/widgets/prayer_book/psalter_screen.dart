import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../theme/everforest_colors.dart';

class KathismaModel {
  final int number;
  final String title;
  final List<PsalmModel> psalms;

  const KathismaModel({
    required this.number,
    required this.title,
    required this.psalms,
  });

  factory KathismaModel.fromJson(Map<String, dynamic> json) {
    final rawPsalms = (json['psalms'] as List?) ?? [];
    return KathismaModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      psalms: rawPsalms
          .whereType<Map>()
          .map((p) => PsalmModel.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
    );
  }
}

class PsalmModel {
  final int number;
  final String title;
  final String text;
  final int verseCount;

  const PsalmModel({
    required this.number,
    required this.title,
    required this.text,
    this.verseCount = 0,
  });

  factory PsalmModel.fromJson(Map<String, dynamic> json) {
    return PsalmModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      verseCount: (json['verseCount'] ?? json['verse_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PsalterScreen extends StatefulWidget {
  const PsalterScreen({super.key, this.initialPsalm});
  final int? initialPsalm;

  @override
  State<PsalterScreen> createState() => _PsalterScreenState();
}

class _PsalterScreenState extends State<PsalterScreen> {
  List<KathismaModel> _kathismata = [];
  bool _isLoading = true;
  String? _error;
  double _fontSize = 17.0;
  bool _isParchment = false;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _psalmKeys = {};
  final Map<int, GlobalKey> _kathismaKeys = {};
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadPsalter();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPsalter() async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/psalter');
      if (data is Map && data['kathismata'] is List) {
        final list = (data['kathismata'] as List)
            .whereType<Map>()
            .map((k) => KathismaModel.fromJson(Map<String, dynamic>.from(k)))
            .toList();

        for (final k in list) {
          _kathismaKeys[k.number] = GlobalKey();
          for (final p in k.psalms) {
            _psalmKeys[p.number] = GlobalKey();
          }
        }

        if (mounted) {
          setState(() {
            _kathismata = list;
            _isLoading = false;
          });

          if (widget.initialPsalm != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToPsalm(widget.initialPsalm!);
            });
          }
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Αδυναμία φόρτωσης Ψαλτηρίου.';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToPsalm(int psalmNum) {
    final key = _psalmKeys[psalmNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.08,
      );
    }
  }

  void _scrollToKathisma(int kathismaNum) {
    final key = _kathismaKeys[kathismaNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  void _showIndexSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: EverforestColors.bg1,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EverforestColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const TabBar(
                  indicatorColor: EverforestColors.yellow,
                  labelColor: EverforestColors.yellow,
                  unselectedLabelColor: EverforestColors.grey,
                  tabs: [
                    Tab(text: 'Καθίσματα (1-20)'),
                    Tab(text: 'Ψαλμοί (1-150)'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Kathismata List
                      ListView.separated(
                        itemCount: _kathismata.length,
                        separatorBuilder: (_, __) => const Divider(color: EverforestColors.bg2, height: 1),
                        itemBuilder: (context, idx) {
                          final k = _kathismata[idx];
                          final firstP = k.psalms.isNotEmpty ? k.psalms.first.number : 1;
                          final lastP = k.psalms.isNotEmpty ? k.psalms.last.number : 1;
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: EverforestColors.yellow.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${k.number}',
                                style: const TextStyle(
                                  color: EverforestColors.yellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            title: Text(
                              k.title.isNotEmpty ? k.title : 'Κάθισμα ${_getGreekNum(k.number)}',
                              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Ψαλμοί $firstP–$lastP',
                              style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: EverforestColors.grey),
                            onTap: () {
                              Navigator.pop(ctx);
                              _scrollToKathisma(k.number);
                            },
                          );
                        },
                      ),
                      // Psalms Grid
                      GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: 150,
                        itemBuilder: (context, idx) {
                          final pNum = idx + 1;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.pop(ctx);
                              _scrollToPsalm(pNum);
                            },
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: EverforestColors.bg0,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: EverforestColors.bg2),
                              ),
                              child: Text(
                                '$pNum',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getGreekNum(int n) {
    const numerals = ['', 'Α\'', 'Β\'', 'Γ\'', 'Δ\'', 'Ε\'', 'Ϛ\'', 'Ζ\'', 'Η\'', 'Θ\'', 'Ι\'',
      'ΙΑ\'', 'ΙΒ\'', 'ΙΓ\'', 'ΙΔ\'', 'ΙΕ\'', 'ΙϚ\'', 'ΙΖ\'', 'ΙΗ\'', 'ΙΘ\'', 'Κ\''];
    if (n >= 1 && n < numerals.length) return numerals[n];
    return '$n';
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
                  hintText: 'Αναζήτηση στους 150 Ψαλμούς...',
                  hintStyle: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              )
            : Text(
                'Ψαλτήριον του Δαυΐδ',
                style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: 16),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: EverforestColors.red)))
              : Stack(
                  children: [
                    // Continuous Scrolling Text
                    ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                      itemCount: _kathismata.length,
                      itemBuilder: (context, kIdx) {
                        final kathisma = _kathismata[kIdx];

                        return Container(
                          key: _kathismaKeys[kathisma.number],
                          margin: const EdgeInsets.only(bottom: 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Kathisma Header Banner
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: rubricColor.withValues(alpha: _isParchment ? 0.12 : 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: rubricColor.withValues(alpha: 0.35)),
                                ),
                                child: Text(
                                  kathisma.title.isNotEmpty
                                      ? kathisma.title.toUpperCase()
                                      : 'ΚΑΘΙΣΜΑ ${_getGreekNum(kathisma.number)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: rubricColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Psalms inside this Kathisma
                              ...kathisma.psalms.map((psalm) {
                                if (_searchQuery.isNotEmpty &&
                                    !psalm.text.toLowerCase().contains(_searchQuery) &&
                                    !psalm.title.toLowerCase().contains(_searchQuery) &&
                                    !psalm.number.toString().contains(_searchQuery)) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  key: _psalmKeys[psalm.number],
                                  margin: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Psalm Title & Number
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: EverforestColors.yellow.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'ΨΑΛΜΟΣ ${psalm.number}ος',
                                              style: const TextStyle(
                                                color: EverforestColors.yellow,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (psalm.title.isNotEmpty)
                                            Expanded(
                                              child: Text(
                                                psalm.title,
                                                style: TextStyle(
                                                  color: rubricColor,
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: _fontSize * 0.78,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      // Psalm Body Text
                                      SelectableText(
                                        psalm.text,
                                        style: TextStyle(
                                          color: fgColor,
                                          fontSize: _fontSize,
                                          height: 1.65,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Divider(color: EverforestColors.bg2.withValues(alpha: 0.5), height: 1),
                                    ],
                                  ),
                                );
                              }),

                              // End of Kathisma Trisagion & Doxology Note
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isParchment ? const Color(0xFFEBE0C5) : EverforestColors.bg1,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Δόξα Πατρί καὶ Υἱῷ καὶ Ἁγίῳ Πνεύματι, καὶ νῦν καὶ ἀεὶ καὶ εἰς τοὺς αἰῶνας τῶν αἰώνων. Ἀμήν.\nἈλληλούϊα, Ἀλληλούϊα, Ἀλληλούϊα, δόξα σοι ὁ Θεός. (ἐκ γ\')\nΚύριε, ἐλέησον. (ἐκ γ\') Δόξα... Καὶ νῦν...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: rubricColor,
                                    fontSize: _fontSize * 0.85,
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Floating Bottom Index Pill
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
                            onTap: _showIndexSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.format_list_numbered_rounded, color: EverforestColors.bg0, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Επιλογή Ψαλμού / Καθίσματος',
                                    style: TextStyle(
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
