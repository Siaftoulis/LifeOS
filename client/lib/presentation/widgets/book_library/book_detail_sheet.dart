import 'package:flutter/material.dart';
import '../../../../core/repositories/book_repository.dart';
import '../../../../database/database.dart';
import '../../../../theme/everforest_colors.dart';
import 'audio_player_widget.dart';
import 'cbz_reader_screen.dart';
import 'epub_reader_screen.dart';

class BookDetailSheet extends StatefulWidget {
  const BookDetailSheet({
    super.key,
    required this.book,
    this.audiobook,
  });

  final Book book;
  final Audiobook? audiobook;

  static Future<void> show(
    BuildContext context, {
    required Book book,
    Audiobook? audiobook,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookDetailSheet(book: book, audiobook: audiobook),
    );
  }

  @override
  State<BookDetailSheet> createState() => _BookDetailSheetState();
}

class _BookDetailSheetState extends State<BookDetailSheet> {
  late int _currentPage;
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
  }

  Future<void> _saveProgress() async {
    setState(() => _isSavingProgress = true);
    await BookRepository.instance.updateProgress(
      widget.book.id,
      _currentPage,
      widget.book.totalPages,
    );
    if (mounted) {
      setState(() => _isSavingProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reading progress saved (Page $_currentPage)'),
          backgroundColor: EverforestColors.bg1,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Delete Book?',
            style: TextStyle(color: EverforestColors.fg)),
        content: Text(
          'Are you sure you want to remove "${widget.book.title}" from your library?',
          style: const TextStyle(color: EverforestColors.grey),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel',
                style: TextStyle(color: EverforestColors.grey)),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: EverforestColors.red),
            child: const Text('Delete',
                style: TextStyle(color: EverforestColors.bg0)),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await BookRepository.instance.deleteBook(widget.book.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${widget.book.title}" from library'),
            backgroundColor: EverforestColors.bg1,
          ),
        );
      }
    }
  }

  void _openReader() {
    Navigator.pop(context);
    final isAudio = widget.audiobook != null && widget.audiobook!.id.isNotEmpty;
    if (isAudio) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) =>
            AudioPlayerWidget(book: widget.book, audiobook: widget.audiobook!),
      );
    } else if (widget.book.filePath.toLowerCase().endsWith('.cbz')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CBZReaderScreen(book: widget.book)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EPUBReaderScreen(book: widget.book)),
      );
    }
  }

  String _getFormatBadge() {
    if (widget.audiobook != null && widget.audiobook!.id.isNotEmpty) {
      return 'AUDIOBOOK';
    }
    if (widget.book.filePath.toLowerCase().endsWith('.cbz')) {
      return 'CBZ / MANGA';
    }
    return 'EPUB EBOOK';
  }

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    final totalPages =
        widget.book.totalPages > 0 ? widget.book.totalPages : 1;
    final progressPct = (_currentPage / totalPages).clamp(0.0, 1.0);
    final isAudio = widget.audiobook != null && widget.audiobook!.id.isNotEmpty;
    final formatBadge = _getFormatBadge();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 40,
            offset: Offset(0, -10),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Header: Cover Art + Title + Author + Format Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 145,
                        decoration: BoxDecoration(
                          color: isAudio
                              ? EverforestColors.blue
                              : EverforestColors.green,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (isAudio
                                      ? EverforestColors.blue
                                      : EverforestColors.green)
                                  .withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            isAudio
                                ? Icons.headphones_rounded
                                : Icons.menu_book_rounded,
                            size: 48,
                            color: EverforestColors.bg0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isAudio
                                        ? EverforestColors.blue
                                        : EverforestColors.green)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (isAudio
                                          ? EverforestColors.blue
                                          : EverforestColors.green)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                formatBadge,
                                style: TextStyle(
                                  color: isAudio
                                      ? EverforestColors.blue
                                      : EverforestColors.green,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.book.title,
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.book.author ?? 'Unknown Author',
                              style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$totalPages total pages',
                              style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Reading Progress Tracker Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Reading Progress',
                              style: TextStyle(
                                color: EverforestColors.fg,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${(progressPct * 100).toStringAsFixed(0)}% (Page $_currentPage / $totalPages)',
                              style: const TextStyle(
                                color: EverforestColors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPct,
                            backgroundColor: EverforestColors.bg0,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                EverforestColors.green),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: EverforestColors.green,
                            thumbColor: EverforestColors.green,
                            inactiveTrackColor: EverforestColors.bg0,
                          ),
                          child: Slider(
                            value: _currentPage.toDouble(),
                            min: 0,
                            max: totalPages.toDouble(),
                            divisions: totalPages > 1 ? totalPages : 1,
                            onChanged: (val) {
                              setState(() => _currentPage = val.round());
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            icon: _isSavingProgress
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: EverforestColors.bg0,
                                    ),
                                  )
                                : const Icon(Icons.bookmark_added_rounded,
                                    size: 16),
                            label: const Text('Update Progress'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EverforestColors.green,
                              foregroundColor: EverforestColors.bg0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _isSavingProgress ? null : _saveProgress,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Open Reader Trigger Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        isAudio
                            ? Icons.headphones_rounded
                            : Icons.auto_stories_rounded,
                        size: 20,
                      ),
                      label: Text(
                        isAudio
                            ? 'Listen to Audiobook'
                            : 'Open Reader (${_currentPage > 0 ? 'Resume Page $_currentPage' : 'Start Reading'})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAudio
                            ? EverforestColors.blue
                            : EverforestColors.green,
                        foregroundColor: EverforestColors.bg0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _openReader,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Highlights / Quotes Section
                  const Text(
                    'HIGHLIGHTS & NOTES',
                    style: TextStyle(
                      color: EverforestColors.grey,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<BookHighlight>>(
                    stream:
                        db.booksDao.watchHighlightsForBook(widget.book.id),
                    builder: (context, snapshot) {
                      final highlights = snapshot.data ?? [];
                      if (highlights.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'No highlights saved yet.\nSelect text while reading to highlight quotes!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: EverforestColors.grey, fontSize: 13),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: highlights.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final h = highlights[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: EverforestColors.bg1,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: EverforestColors.yellow
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '“${h.textContent}”',
                                  style: const TextStyle(
                                    color: EverforestColors.fg,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                ),
                                if (h.noteContent != null &&
                                    h.noteContent!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'Note: ${h.noteContent}',
                                    style: const TextStyle(
                                      color: EverforestColors.yellow,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Delete Book Action
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: EverforestColors.red, size: 18),
                      label: const Text('Delete from Library',
                          style: TextStyle(color: EverforestColors.red)),
                      onPressed: _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
