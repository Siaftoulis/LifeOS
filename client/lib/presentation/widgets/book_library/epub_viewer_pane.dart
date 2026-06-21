import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class EPUBViewerPane extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String selectedText;
  final ValueChanged<String> onSelectionChanged;
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;

  const EPUBViewerPane({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.selectedText,
    required this.onSelectionChanged,
    required this.onPrevPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final textContent = 'Chapter $currentPage\n\n'
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
        'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
        'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
        'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n'
        '(Select text to highlight, or tap left/right edges to turn pages)';

    return GestureDetector(
      onTapUp: (details) {
        double width = MediaQuery.of(context).size.width;
        if (details.globalPosition.dx < width * 0.3) {
          onPrevPage();
        } else if (details.globalPosition.dx > width * 0.7) {
          onNextPage();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: EverforestColors.bg1,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  textContent,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 18, height: 1.6),
                  onSelectionChanged: (selection, cause) {
                    final text = selection.textInside(textContent);
                    onSelectionChanged(text.trim());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Page $currentPage of $totalPages',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
