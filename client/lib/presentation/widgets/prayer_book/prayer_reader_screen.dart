import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

class PrayerReaderScreen extends StatefulWidget {
  const PrayerReaderScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    this.date,
  });

  final String serviceId;
  final String serviceTitle;
  final DateTime? date;

  @override
  State<PrayerReaderScreen> createState() => _PrayerReaderScreenState();
}

class _PrayerReaderScreenState extends State<PrayerReaderScreen> {
  double _fontSize = 17.0;
  bool _isParchmentMode = false;
  bool _isAutoScrolling = false;
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();
  PrayerServiceModel? _service;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadService();
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadService() async {
    final svc = await PrayerRepository.instance
        .fetchService(widget.serviceId, widget.date);
    if (mounted) {
      setState(() {
        _service = svc;
        _isLoading = false;
      });
    }
  }

  void _toggleAutoScroll() {
    setState(() => _isAutoScrolling = !_isAutoScrolling);
    if (_isAutoScrolling) {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.offset;
          if (currentScroll < maxScroll) {
            _scrollController.jumpTo(currentScroll + 1.2);
          } else {
            _scrollTimer?.cancel();
            setState(() => _isAutoScrolling = false);
          }
        }
      });
    } else {
      _scrollTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    final bgColor = _isParchmentMode
        ? const Color(0xFF26201A)
        : EverforestColors.bg0;
    final cardBgColor = _isParchmentMode
        ? const Color(0xFF332B23)
        : EverforestColors.bg1;
    final textColor = _isParchmentMode
        ? const Color(0xFFEADBCE)
        : EverforestColors.fg;
    final rubricColor = _isParchmentMode
        ? const Color(0xFFE06C75)
        : EverforestColors.red;
    final accentGold = _isParchmentMode
        ? const Color(0xFFE5C07B)
        : EverforestColors.yellow;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: EverforestColors.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.serviceTitle,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_service?.subtitle.isNotEmpty ?? false)
              Text(
                _service!.subtitle,
                style: const TextStyle(
                  color: EverforestColors.grey,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        actions: [
          // Parchment / Dark Mode Toggle
          IconButton(
            icon: Icon(
              _isParchmentMode
                  ? Icons.menu_book_rounded
                  : Icons.auto_stories_rounded,
              color: _isParchmentMode ? accentGold : EverforestColors.grey,
            ),
            tooltip: _isParchmentMode
                ? 'Dark Theme'
                : 'Parchment Warm Theme',
            onPressed: () =>
                setState(() => _isParchmentMode = !_isParchmentMode),
          ),

          // Text Size Zoom Controls
          IconButton(
            icon: const Text('Α-',
                style: TextStyle(
                    color: EverforestColors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
            tooltip: 'Decrease font size',
            onPressed: () {
              if (_fontSize > 13) setState(() => _fontSize -= 1.5);
            },
          ),
          IconButton(
            icon: const Text('Α+',
                style: TextStyle(
                    color: EverforestColors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            tooltip: 'Increase font size',
            onPressed: () {
              if (_fontSize < 28) setState(() => _fontSize += 1.5);
            },
          ),

          // Favorite / Bookmark
          ValueListenableBuilder<Set<String>>(
            valueListenable: PrayerRepository.instance.favoriteIds,
            builder: (context, favs, _) {
              final isFav = favs.contains(widget.serviceId);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFav ? EverforestColors.yellow : EverforestColors.grey,
                ),
                tooltip: isFav ? 'Bookmarked' : 'Add to Favorites',
                onPressed: () =>
                    PrayerRepository.instance.toggleFavorite(widget.serviceId),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isAutoScrolling
            ? EverforestColors.red
            : EverforestColors.green,
        foregroundColor: EverforestColors.bg0,
        icon: Icon(
          _isAutoScrolling
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
        ),
        label: Text(
          _isAutoScrolling ? 'Παύση κύλισης' : 'Αυτόματη κύλιση',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: _toggleAutoScroll,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EverforestColors.yellow),
            )
          : _service == null
              ? const Center(
                  child: Text('Service not available',
                      style: TextStyle(color: EverforestColors.grey)),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Byzantine Cross Ornament
                      Center(
                        child: Text(
                          '☩ ☩ ☩',
                          style: TextStyle(
                            color: accentGold.withValues(alpha: 0.6),
                            fontSize: 18,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sections
                      ..._service!.sections.map((section) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Section Header with Dynamic Typikon Badge
                              if (section.header.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        section.header,
                                        style: TextStyle(
                                          color: rubricColor,
                                          fontSize: _fontSize * 0.9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    if (section.isDynamic)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: accentGold
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color: accentGold
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.auto_awesome_rounded,
                                                color: accentGold, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              'ΤΥΠΙΚΟΝ ΗΜΕΡΑΣ',
                                              style: TextStyle(
                                                color: accentGold,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Section Content Container
                              Container(
                                width: double.infinity,
                                padding: section.isDynamic
                                    ? const EdgeInsets.all(16)
                                    : EdgeInsets.zero,
                                decoration: section.isDynamic
                                    ? BoxDecoration(
                                        color: cardBgColor,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: accentGold
                                              .withValues(alpha: 0.2),
                                        ),
                                      )
                                    : null,
                                child: Text(
                                  section.content,
                                  style: TextStyle(
                                    color: section.isRubric
                                        ? rubricColor
                                        : textColor,
                                    fontSize: _fontSize,
                                    fontStyle: section.isRubric
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    height: 1.7,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          '☩ ☩ ☩',
                          style: TextStyle(
                            color: accentGold.withValues(alpha: 0.6),
                            fontSize: 18,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
