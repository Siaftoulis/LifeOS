import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import 'audio_player_widget.dart';
import 'epub_reader_screen.dart';

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
        final progress = book.totalPages > 0 ? book.currentPage / book.totalPages : 0.0;

        return GestureDetector(
          onTap: () {
            if (isAudio) {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => AudioPlayerWidget(book: book, audiobook: audiobook),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EPUBReaderScreen(book: book)),
              );
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: EverforestColors.bg1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EverforestColors.bg2, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAudio ? EverforestColors.blue : EverforestColors.green,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Icon(
                      isAudio ? Icons.headphones : Icons.book,
                      size: 48,
                      color: EverforestColors.bg0,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        book.author ?? 'Unknown',
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: EverforestColors.bg2,
                        color: EverforestColors.green,
                        minHeight: 4,
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
