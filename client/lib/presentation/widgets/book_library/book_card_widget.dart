import 'package:flutter/material.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';
import 'book_detail_sheet.dart';

class BookCardWidget extends StatelessWidget {
  final Book book;

  const BookCardWidget({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final db = AppDatabase.instance;
    return StreamBuilder<List<Audiobook>>(
      stream: db.booksDao.watchAllAudiobooks(),
      builder: (context, audioSnapshot) {
        final audiobooks = audioSnapshot.data ?? [];
        final audiobook = audiobooks.firstWhere(
          (a) => a.bookId == book.id,
          orElse: () => Audiobook(
            id: '',
            bookId: '',
            filePath: '',
            durationSeconds: 0,
            currentSeconds: 0,
            updatedAt: 0,
            isDirty: 0,
          ),
        );
        final isAudio = audiobook.id.isNotEmpty;
        final totalPages = book.totalPages > 0 ? book.totalPages : 1;
        final progress = (book.currentPage / totalPages).clamp(0.0, 1.0);
        final isCBZ = book.filePath.toLowerCase().endsWith('.cbz');

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => BookDetailSheet.show(
            context,
            book: book,
            audiobook: isAudio ? audiobook : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: EverforestColors.bg1,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Cover Box with Format Badge
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: isAudio
                                ? [
                                    EverforestColors.blue
                                        .withValues(alpha: 0.8),
                                    EverforestColors.blue,
                                  ]
                                : isCBZ
                                    ? [
                                        EverforestColors.purple
                                            .withValues(alpha: 0.8),
                                        EverforestColors.purple,
                                      ]
                                    : [
                                        EverforestColors.green
                                            .withValues(alpha: 0.8),
                                        EverforestColors.green,
                                      ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isAudio
                                ? Icons.headphones_rounded
                                : isCBZ
                                    ? Icons.collections_bookmark_rounded
                                    : Icons.menu_book_rounded,
                            size: 52,
                            color: EverforestColors.bg0,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAudio
                                ? 'AUDIO'
                                : isCBZ
                                    ? 'CBZ'
                                    : 'EPUB',
                            style: TextStyle(
                              color: isAudio
                                  ? EverforestColors.blue
                                  : isCBZ
                                      ? EverforestColors.purple
                                      : EverforestColors.green,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (progress > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.black26,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            minHeight: 4,
                          ),
                        ),
                    ],
                  ),
                ),

                // Card Bottom info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        book.author ?? 'Unknown Author',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            progress > 0
                                ? '${(progress * 100).toStringAsFixed(0)}%'
                                : 'Unread',
                            style: TextStyle(
                              color: progress > 0
                                  ? EverforestColors.green
                                  : EverforestColors.grey,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${book.currentPage}/${book.totalPages} p.',
                            style: const TextStyle(
                              color: EverforestColors.grey,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
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
}
