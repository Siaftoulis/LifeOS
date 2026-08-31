import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../theme/everforest_colors.dart';
import 'prayer_reader_screen.dart';

class PsalterScreen extends StatefulWidget {
  const PsalterScreen({super.key});

  @override
  State<PsalterScreen> createState() => _PsalterScreenState();
}

class _PsalterScreenState extends State<PsalterScreen> {
  List<Kathisma> _kathismata = [];
  bool _isLoading = true;
  String? _error;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadPsalter();
  }

  Future<void> _loadPsalter() async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/psalter');

      if (data is Map && data['kathismata'] is List) {
        final kathismata = (data['kathismata'] as List)
            .map((k) => Kathisma.fromJson(k))
            .toList();
        setState(() {
          _kathismata = kathismata;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load Psalter';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error';
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final data = await ApiClient.instance.getDaemon(
        '/api/v1/prayers/psalter/search?q=${Uri.encodeComponent(query)}',
      );

      if (data is Map && data['results'] is List) {
        final results = (data['results'] as List)
            .map((r) => SearchResult.fromJson(r))
            .toList();
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  void _openPsalm(int psalmNumber, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrayerReaderScreen(
          serviceId: 'psalm_$psalmNumber',
          serviceTitle: title,
        ),
      ),
    );
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EverforestColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '📜',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ψαλτήριον',
                  style: TextStyle(
                    color: EverforestColors.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '150 Ψαλμοί του Δαυΐδ',
                  style: TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: EverforestColors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: EverforestColors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPsalter,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        onChanged: _search,
                        style: const TextStyle(color: EverforestColors.fg),
                        decoration: InputDecoration(
                          hintText: 'Αναζήτηση στους Ψαλμούς...',
                          hintStyle: TextStyle(
                              color: EverforestColors.grey.withValues(alpha: 0.6)),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: EverforestColors.grey, size: 20),
                          suffixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: EverforestColors.yellow),
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: EverforestColors.bg1,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),

                    // Search results or Kathismata list
                    if (_searchResults.isNotEmpty)
                      Expanded(
                        child: _buildSearchResults(),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _kathismata.length,
                          itemBuilder: (context, index) {
                            return _buildKathismaCard(_kathismata[index]);
                          },
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openPsalm(result.psalmNumber, result.psalmTitle),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: EverforestColors.yellow
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Ψ${result.psalmNumber}',
                            style: const TextStyle(
                              color: EverforestColors.yellow,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Καθίσμα ${result.kathisma}',
                          style: const TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.snippet,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKathismaCard(Kathisma kathisma) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: EverforestColors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${kathisma.number}',
                    style: const TextStyle(
                      color: EverforestColors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kathisma.title,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Ψαλμοί ${kathisma.psalms.first.number}–${kathisma.psalms.last.number}',
                      style: const TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: kathisma.psalms.map((psalm) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: EverforestColors.bg2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${psalm.number}',
                    style: const TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              title: Text(
                psalm.title,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                '${psalm.verseCount} στίχοι',
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: EverforestColors.grey, size: 18),
              onTap: () => _openPsalm(psalm.number, psalm.title),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class Kathisma {
  final int number;
  final String title;
  final List<PsalmItem> psalms;

  Kathisma({
    required this.number,
    required this.title,
    required this.psalms,
  });

  factory Kathisma.fromJson(Map<String, dynamic> json) {
    return Kathisma(
      number: json['number'] ?? 0,
      title: json['title'] ?? '',
      psalms: (json['psalms'] as List?)
              ?.map((p) => PsalmItem.fromJson(p))
              .toList() ??
          [],
    );
  }
}

class PsalmItem {
  final int number;
  final String title;
  final int verseCount;

  PsalmItem({
    required this.number,
    required this.title,
    required this.verseCount,
  });

  factory PsalmItem.fromJson(Map<String, dynamic> json) {
    return PsalmItem(
      number: json['number'] ?? 0,
      title: json['title'] ?? '',
      verseCount: json['verseCount'] ?? 0,
    );
  }
}

class SearchResult {
  final int psalmNumber;
  final String psalmTitle;
  final int kathisma;
  final String snippet;

  SearchResult({
    required this.psalmNumber,
    required this.psalmTitle,
    required this.kathisma,
    required this.snippet,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      psalmNumber: json['psalm_number'] ?? 0,
      psalmTitle: json['psalm_title'] ?? '',
      kathisma: json['kathisma'] ?? 0,
      snippet: json['snippet'] ?? '',
    );
  }
}
