import 'package:flutter/material.dart';
import 'editor_theme.dart';
import '../../core/rewards/point_star_system.dart';

class MarkdownFocusViewport extends StatefulWidget {
  final String initialText;
  final ValueChanged<String> onTextChanged;

  const MarkdownFocusViewport({
    Key? key,
    required this.initialText,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  State<MarkdownFocusViewport> createState() => _MarkdownFocusViewportState();
}

class _MarkdownFocusViewportState extends State<MarkdownFocusViewport> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    widget.onTextChanged(_controller.text);
    // Rough simulation of logging an hour of editing.
    // Real implementation would use a timer.
    if (_controller.text.length % 500 == 0) {
      PointStarSystem().logEditingHour();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg1,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        style: const TextStyle(color: Color(0xFFfafafa), fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Start typing...',
          hintStyle: TextStyle(color: EverforestColors.grey),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
