import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../core/repositories/offline_prayer_data.dart';
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
  final String translation;
  final int verseCount;

  const PsalmModel({
    required this.number,
    required this.title,
    required this.text,
    this.translation = '',
    this.verseCount = 0,
  });

  factory PsalmModel.fromJson(Map<String, dynamic> json) {
    return PsalmModel(
      number: (json['number'] as num?)?.toInt() ?? 1,
      title: json['title']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      translation: json['translation']?.toString() ?? '',
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
  bool _showTranslation = false;
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
    List<KathismaModel> list = [];
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/psalter');
      if (data is Map && data['kathismata'] is List) {
        list = (data['kathismata'] as List)
            .whereType<Map>()
            .map((k) => KathismaModel.fromJson(Map<String, dynamic>.from(k)))
            .toList();
      }
    } catch (_) {}

    // Offline fallback from bundled assets
    if (list.isEmpty) {
      list = await OfflinePrayerData.loadPsalter();
    }

    if (list.isNotEmpty) {
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
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.1,
      );
    }
  }

  void _scrollToKathisma(int kathismaNum) {
    final key = _kathismaKeys[kathismaNum];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    }
  }

  void _showIndexSheet() {
    final bgColor = _isParchment ? const Color(0xFFF4ECD8) : EverforestColors.bg0;
    final fgColor = _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollCtrl) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EverforestColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.format_list_numbered_rounded, color: EverforestColors.yellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Πίνακας Ψαλτηρίου (20 Καθίσματα)',
                        style: TextStyle(
                          color: fgColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    itemCount: _kathismata.length,
                    itemBuilder: (context, idx) {
                      final k = _kathismata[idx];
                      return ExpansionTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: EverforestColors.yellow.withValues(alpha: 0.2),
                          child: Text(
                            '${k.number}',
                            style: const TextStyle(
                              color: EverforestColors.yellow,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          k.title,
                          style: TextStyle(color: fgColor, fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: k.psalms.map((p) {
                                return ActionChip(
                                  backgroundColor: EverforestColors.bg2,
                                  label: Text(
                                    'Ψαλμός ${p.number}',
                                    style: const TextStyle(fontSize: 12, color: EverforestColors.fg),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _scrollToPsalm(p.number);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.arrow_forward_rounded, size: 16, color: EverforestColors.yellow),
                            title: Text('Μετάβαση στην αρχή του ${k.title}', style: const TextStyle(fontSize: 12, color: EverforestColors.yellow)),
                            onTap: () {
                              Navigator.pop(context);
                              _scrollToKathisma(k.number);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
                '\u03a1\u03c5\u03b8\u03bc\u03af\u03c3\u03b5\u03b9\u03c2 \u0391\u03bd\u03ac\u03b3\u03bd\u03c9\u03c3\u03b7\u03c2',
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              // Theme Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\u0398\u03ad\u03bc\u03b1 \u03a0\u03b5\u03c1\u03b3\u03b1\u03bc\u03b7\u03bd\u03ae\u03c2',
                    style: TextStyle(color: fgColor, fontSize: 14),
                  ),
                  Switch.adaptive(
                    value: _isParchment,
                    activeThumbColor: EverforestColors.yellow,
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
                    '\u039c\u03ad\u03b3\u03b5\u03b8\u03bf\u03c2 \u0393\u03c1\u03b1\u03bc\u03bc\u03b1\u03c4\u03bf\u03c3\u03b5\u03b9\u03c1\u03ac\u03c2',
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
                        '${_fontSize.toStringAsFixed(1)}',
                        style: TextStyle(color: fgColor, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: fgColor),
                        onPressed: _fontSize < 28
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
    final rubricColor = _isParchment ? const Color(0xFF8B2500) : EverforestColors.red;

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
                  hintText: '\u0391\u03bd\u03b1\u03b6\u03ae\u03c4\u03b7\u03c3\u03b7 \u03c3\u03c4\u03bf\u03c5\u03c2 150 \u03a8\u03b1\u03bb\u03bc\u03bf\u03cd\u03c2...',
                  hintStyle: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              )
            : Text(
                '\u03a8\u03b1\u03bb\u03c4\u03ae\u03c1\u03b9\u03bf\u03bd \u03c4\u03bf\u03c5 \u0394\u03b1\u03c5\u0390\u03b4',
                style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16),
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
            icon: Icon(Icons.translate_rounded, color: _showTranslation ? EverforestColors.aqua : fgColor, size: 20),
            tooltip: _showTranslation ? '\u0391\u03c0\u03cc\u03ba\u03c1\u03c5\u03c8\u03b7 \u039c\u03b5\u03c4\u03ac\u03c6\u03c1\u03b1\u03c3\u03b7\u03c2' : '\u0395\u03bc\u03c6\u03ac\u03bd\u03b9\u03c3\u03b7 \u039c\u03b5\u03c4\u03ac\u03c6\u03c1\u03b1\u03c3\u03b7\u03c2',
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          if (isMobile)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.tune_rounded, color: fgColor, size: 20),
              tooltip: '\u03a1\u03c5\u03b8\u03bc\u03af\u03c3\u03b5\u03b9\u03c2',
              onPressed: () => _openSettingsSheet(context, fgColor),
            )
          else ...[
            IconButton(
              icon: Icon(_isParchment ? Icons.dark_mode_rounded : Icons.menu_book_rounded, color: fgColor, size: 20),
              tooltip: '\u0395\u03bd\u03b1\u03bb\u03bb\u03b1\u03b3\u03ae \u03b8\u03ad\u03bc\u03b1\u03c4\u03bf\u03c2',
              onPressed: () => setState(() => _isParchment = !_isParchment),
            ),
            IconButton(
              icon: Icon(Icons.text_increase_rounded, color: fgColor, size: 20),
              tooltip: '\u0391\u03cd\u03be\u03b7\u03c3\u03b7 \u03b3\u03c1\u03b1\u03bc\u03bc\u03b1\u03c4\u03bf\u03c3\u03b5\u03b9\u03c1\u03ac\u03c2',
              onPressed: () {
                if (_fontSize < 28) setState(() => _fontSize += 1.5);
              },
            ),
            IconButton(
              icon: Icon(Icons.text_decrease_rounded, color: fgColor, size: 20),
              tooltip: '\u039c\u03b5\u03af\u03c9\u03c3\u03b7 \u03b3\u03c1\u03b1\u03bc\u03bc\u03b1\u03c4\u03bf\u03c3\u03b5\u03b9\u03c1\u03ac\u03c2',
              onPressed: () {
                if (_fontSize > 13) setState(() => _fontSize -= 1.5);
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: EverforestColors.red)))
              : Stack(
                  children: [
                    // Smooth SelectionArea Reading (Zero Touch Scroll Traps)
                    SelectionArea(
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, 14, isMobile ? 14 : 24, 90),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: EverforestColors.yellow.withValues(alpha: _isParchment ? 0.15 : 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: EverforestColors.yellow.withValues(alpha: 0.3)),
                                  ),
                                  child: Text(
                                    kathisma.title.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: EverforestColors.yellow,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Psalms in this Kathisma
                                ...kathisma.psalms.map((psalm) {
                                  if (_searchQuery.isNotEmpty &&
                                      !psalm.text.toLowerCase().contains(_searchQuery) &&
                                      !psalm.title.toLowerCase().contains(_searchQuery) &&
                                      !psalm.translation.toLowerCase().contains(_searchQuery) &&
                                      !psalm.number.toString().contains(_searchQuery)) {
                                    return const SizedBox.shrink();
                                  }

                                  return Container(
                                    key: _psalmKeys[psalm.number],
                                    margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
                                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: isMobile ? 4 : 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                        // Psalm Body Text (Septuagint)
                                        Text(
                                          psalm.text,
                                          style: TextStyle(
                                            color: fgColor,
                                            fontSize: _fontSize,
                                            height: 1.65,
                                            fontFamily: 'serif',
                                          ),
                                        ),
                                        // Modern Greek Translation (if toggled)
                                        if (_showTranslation && psalm.translation.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: EverforestColors.aqua.withValues(alpha: _isParchment ? 0.08 : 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: EverforestColors.aqua.withValues(alpha: 0.3)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Row(
                                                  children: [
                                                    Icon(Icons.translate_rounded, size: 14, color: EverforestColors.aqua),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'ΝΕΟΕΛΛΗΝΙΚΗ ΑΠΟΔΟΣΗ',
                                                      style: TextStyle(
                                                        color: EverforestColors.aqua,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 11,
                                                        letterSpacing: 0.8,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  psalm.translation,
                                                  style: TextStyle(
                                                    color: _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg,
                                                    fontSize: _fontSize * 0.94,
                                                    height: 1.6,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
                                    'Δόξα Πατρὶ καὶ Υἱῷ καὶ Ἁγίῳ Πνεύματι, καὶ νῦν καὶ ἀεὶ καὶ εἰς τοὺς αἰῶνας τῶν αἰώνων. Ἀμήν.\nἈλληλούϊα, Ἀλληλούϊα, Ἀλληλούϊα, δόξα σοι ὁ Θεός. (ἐκ γ\')\nΚύριε, ἐλέησον. (ἐκ γ\') Δόξα... Καὶ νῦν...',
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
