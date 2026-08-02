import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

/// High-performance TextEditingController with live Markdown syntax highlighting,
/// block styling (H1-H3, Lists, Checkboxes, Quotes, Dividers, Code, Wikilinks),
/// and keyboard auto-formatting shortcuts.
class ZenMarkdownEditingController extends TextEditingController {
  ZenMarkdownEditingController({super.text});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final baseStyle = style ?? const TextStyle(color: EverforestColors.fg, fontSize: 16, height: 1.6);
    final lines = text.split('\n');
    final List<TextSpan> lineSpans = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isLastLine = i == lines.length - 1;
      final lineText = isLastLine ? line : '$line\n';

      lineSpans.add(_formatLine(lineText, baseStyle));
    }

    return TextSpan(style: baseStyle, children: lineSpans);
  }

  TextSpan _formatLine(String line, TextStyle baseStyle) {
    // Heading 1: # Title
    if (line.startsWith('# ')) {
      return TextSpan(
        text: line,
        style: baseStyle.copyWith(
          color: EverforestColors.yellow,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // Heading 2: ## Subtitle
    if (line.startsWith('## ')) {
      return TextSpan(
        text: line,
        style: baseStyle.copyWith(
          color: EverforestColors.green,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // Heading 3: ### Section
    if (line.startsWith('### ')) {
      return TextSpan(
        text: line,
        style: baseStyle.copyWith(
          color: EverforestColors.blue,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // Bulleted List: - Item or * Item
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return TextSpan(
        children: [
          TextSpan(text: line.substring(0, 2), style: baseStyle.copyWith(color: EverforestColors.orange, fontWeight: FontWeight.bold)),
          TextSpan(text: line.substring(2), style: baseStyle),
        ],
      );
    }
    // Numbered List: 1. Item
    final numMatch = RegExp(r'^(\d+\.\s)').firstMatch(line);
    if (numMatch != null) {
      final prefix = numMatch.group(1)!;
      return TextSpan(
        children: [
          TextSpan(text: prefix, style: baseStyle.copyWith(color: EverforestColors.purple, fontWeight: FontWeight.bold)),
          TextSpan(text: line.substring(prefix.length), style: baseStyle),
        ],
      );
    }
    // Todo Checkbox: [ ] Task or [x] Task
    if (line.startsWith('[ ] ') || line.startsWith('[] ')) {
      final prefixLen = line.startsWith('[ ] ') ? 4 : 3;
      return TextSpan(
        children: [
          TextSpan(text: '☐ ', style: baseStyle.copyWith(color: EverforestColors.aqua, fontWeight: FontWeight.bold, fontSize: 18)),
          TextSpan(text: line.substring(prefixLen), style: baseStyle),
        ],
      );
    }
    if (line.startsWith('[x] ') || line.startsWith('[X] ')) {
      return TextSpan(
        children: [
          TextSpan(text: '☑ ', style: baseStyle.copyWith(color: EverforestColors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          TextSpan(
            text: line.substring(4),
            style: baseStyle.copyWith(
              color: EverforestColors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }
    // Blockquote: > Quote
    if (line.startsWith('> ')) {
      return TextSpan(
        text: line,
        style: baseStyle.copyWith(
          color: EverforestColors.grey,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    // Divider: ---
    if (line.trim() == '---') {
      return TextSpan(
        text: line,
        style: baseStyle.copyWith(
          color: EverforestColors.purple,
          fontWeight: FontWeight.bold,
          letterSpacing: 4.0,
        ),
      );
    }

    // Default line formatting with inline syntax (Bold, Italic, Code, Wikilinks)
    return _formatInline(line, baseStyle);
  }

  TextSpan _formatInline(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp inlineRegex = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`|\[\[.*?\]\])');
    int start = 0;

    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: baseStyle));
      }
      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(fontWeight: FontWeight.bold, color: EverforestColors.yellow),
        ));
      } else if (matchedText.startsWith('*') && matchedText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(fontStyle: FontStyle.italic, color: EverforestColors.green),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(color: EverforestColors.orange, fontFamily: 'JetBrainsMono', backgroundColor: const Color(0x332E383C)),
        ));
      } else if (matchedText.startsWith('[[') && matchedText.endsWith(']]')) {
        spans.add(TextSpan(
          text: matchedText,
          style: baseStyle.copyWith(color: EverforestColors.blue, decoration: TextDecoration.underline),
        ));
      }
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }

    return TextSpan(children: spans);
  }
}
