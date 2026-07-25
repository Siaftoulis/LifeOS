import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class ZenToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTextChanged;

  const ZenToolbar({
    super.key,
    required this.controller,
    required this.onTextChanged,
  });

  void _wrapSelection(String prefix, String suffix) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      controller.text = '$text$prefix$suffix';
      controller.selection = TextSelection.collapsed(offset: controller.text.length - suffix.length);
    } else {
      final selectedText = selection.textInside(text);
      final newText = selection.textBefore(text) + prefix + selectedText + suffix + selection.textAfter(text);
      controller.text = newText;
      controller.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      );
    }
    onTextChanged();
  }

  void _insertAtLineStart(String prefix) {
    final text = controller.text;
    final selection = controller.selection;
    int start = selection.isValid ? selection.start : text.length;

    int lineStart = text.lastIndexOf('\n', start > 0 ? start - 1 : 0);
    if (lineStart == -1) lineStart = 0; else lineStart++;

    final newText = text.substring(0, lineStart) + prefix + text.substring(lineStart);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: start + prefix.length);
    onTextChanged();
  }

  void _insertTemplate(String template) {
    final text = controller.text;
    final selection = controller.selection;

    if (!selection.isValid) {
      controller.text = '$text\n$template';
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    } else {
      final newText = selection.textBefore(text) + template + selection.textAfter(text);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: selection.start + template.length);
    }
    onTextChanged();
  }

  Widget _buildToolButton(IconData icon, String tooltip, VoidCallback onPressed, {Color? color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, size: 16, color: color ?? EverforestColors.fg),
        ),
      ),
    );
  }

  Widget _buildTextButton(String label, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          child: Text(
            label,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: EverforestColors.bg1,
        border: Border(
          bottom: BorderSide(color: EverforestColors.bg2, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTextButton('H1', 'Heading 1', () => _insertAtLineStart('# ')),
            _buildTextButton('H2', 'Heading 2', () => _insertAtLineStart('## ')),
            _buildTextButton('H3', 'Heading 3', () => _insertAtLineStart('### ')),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8, color: EverforestColors.bg2),
            _buildToolButton(Icons.format_bold, 'Bold', () => _wrapSelection('**', '**')),
            _buildToolButton(Icons.format_italic, 'Italic', () => _wrapSelection('*', '*')),
            _buildToolButton(Icons.strikethrough_s, 'Strikethrough', () => _wrapSelection('~~', '~~')),
            _buildToolButton(Icons.code, 'Inline Code', () => _wrapSelection('`', '`')),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8, color: EverforestColors.bg2),
            _buildToolButton(Icons.format_list_bulleted, 'Bullet List', () => _insertAtLineStart('- ')),
            _buildToolButton(Icons.format_list_numbered, 'Numbered List', () => _insertAtLineStart('1. ')),
            _buildToolButton(Icons.check_box_outlined, 'Task Checkbox', () => _insertAtLineStart('- [ ] ')),
            const VerticalDivider(width: 16, indent: 8, endIndent: 8, color: EverforestColors.bg2),
            _buildToolButton(Icons.info_outline, 'Obsidian Callout', () => _insertTemplate('> [!NOTE]\n> ')),
            _buildToolButton(Icons.data_object, 'Code Block', () => _insertTemplate('```\n\n```')),
            _buildToolButton(Icons.table_chart_outlined, 'Markdown Table', () => _insertTemplate('| Header 1 | Header 2 |\n| --- | --- |\n| Cell 1 | Cell 2 |\n')),
            _buildToolButton(Icons.link, 'Insert Wikilink', () => _wrapSelection('[[', ']]'), color: EverforestColors.green),
          ],
        ),
      ),
    );
  }
}
