import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class HeadingItem {
  final int level;
  final String text;
  final int lineNumber;

  HeadingItem({
    required this.level,
    required this.text,
    required this.lineNumber,
  });
}

class ZenOutlinePanel extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<int> onHeadingSelected;

  const ZenOutlinePanel({
    super.key,
    required this.controller,
    required this.onHeadingSelected,
  });

  @override
  State<ZenOutlinePanel> createState() => _ZenOutlinePanelState();
}

class _ZenOutlinePanelState extends State<ZenOutlinePanel> {
  List<HeadingItem> _headings = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_parseHeadings);
    _parseHeadings();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_parseHeadings);
    super.dispose();
  }

  void _parseHeadings() {
    final text = widget.controller.text;
    final lines = text.split('\n');
    final newHeadings = <HeadingItem>[];

    final regExp = RegExp(r'^(#{1,6})\s+(.*)$');

    for (int i = 0; i < lines.length; i++) {
      final match = regExp.firstMatch(lines[i].trim());
      if (match != null) {
        final hashCount = match.group(1)!.length;
        final headingText = match.group(2)!.trim();
        newHeadings.add(HeadingItem(
          level: hashCount,
          text: headingText,
          lineNumber: i + 1,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _headings = newHeadings;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                const Icon(Icons.format_list_bulleted, color: EverforestColors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'OUTLINE (${_headings.length})',
                  style: const TextStyle(
                    color: EverforestColors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: EverforestColors.bg2),
          Expanded(
            child: _headings.isEmpty
                ? const Center(
                    child: Text(
                      'No headings found in note',
                      style: TextStyle(
                        color: EverforestColors.grey,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _headings.length,
                    itemBuilder: (context, index) {
                      final item = _headings[index];
                      return InkWell(
                        onTap: () => widget.onHeadingSelected(item.lineNumber),
                        hoverColor: Colors.white10,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 16.0 + (item.level - 1) * 16.0,
                            right: 16.0,
                            top: 6.0,
                            bottom: 6.0,
                          ),
                          child: Row(
                            children: [
                              Text(
                                'H${item.level}',
                                style: const TextStyle(
                                  color: EverforestColors.purple,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.text,
                                  style: const TextStyle(
                                    color: EverforestColors.fg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'L${item.lineNumber}',
                                style: const TextStyle(
                                  color: EverforestColors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
