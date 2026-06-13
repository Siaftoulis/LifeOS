import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'epub_reader_screen.dart';
import 'audio_player_widget.dart';
import 'highlight_curtain.dart';

class BookLibraryDashboard extends StatelessWidget {
  const BookLibraryDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIBRARY',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              IconButton(
                icon: Icon(Icons.bookmarks_outlined, color: EverforestColors.fg),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const HighlightCurtain(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: 4, // Stub
              itemBuilder: (context, index) {
                return _buildBookCard(context, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, int index) {
    bool isAudiobook = index % 2 == 1;
    return GestureDetector(
      onTap: () {
        if (isAudiobook) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const AudioPlayerWidget(),
          );
        } else {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EPUBReaderScreen(),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EverforestColors.bg2, width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: EverforestColors.bg2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    isAudiobook ? Icons.headphones : Icons.menu_book,
                    color: EverforestColors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sample Book ${index + 1}',
              style: TextStyle(
                color: EverforestColors.fg,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Unknown Author',
              style: TextStyle(
                color: EverforestColors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.4,
              backgroundColor: EverforestColors.bg0,
              valueColor: AlwaysStoppedAnimation<Color>(EverforestColors.green),
            ),
          ],
        ),
      ),
    );
  }
}
