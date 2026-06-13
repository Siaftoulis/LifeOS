import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class EPUBReaderScreen extends StatefulWidget {
  const EPUBReaderScreen({Key? key}) : super(key: key);

  @override
  _EPUBReaderScreenState createState() => _EPUBReaderScreenState();
}

class _EPUBReaderScreenState extends State<EPUBReaderScreen> {
  int _currentPage = 1;
  final int _totalPages = 342;

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() => _currentPage++);
      // Trigger Point Star logic internally here (1 point per 10 pages)
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg1,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        title: Text(
          'Sample Book Title',
          style: TextStyle(color: EverforestColors.fg, fontSize: 16),
        ),
        iconTheme: IconThemeData(color: EverforestColors.fg),
      ),
      body: GestureDetector(
        onTapUp: (details) {
          double width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < width * 0.3) {
            _prevPage();
          } else if (details.globalPosition.dx > width * 0.7) {
            _nextPage();
          } else {
            // Center tap: toggle UI overlay
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: EverforestColors.bg1,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    'Chapter $_currentPage\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\n\n(Tap left/right edges to turn pages)',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 18,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Page $_currentPage of $_totalPages',
                  style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
