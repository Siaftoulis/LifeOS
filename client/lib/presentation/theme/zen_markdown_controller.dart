import 'package:flutter/material.dart';
import 'package:markdown_editor_live/markdown_editor_live.dart' as mel;
import 'zen_theme_service.dart';

class ZenCheckboxWidget extends StatefulWidget {
  final bool isChecked;
  final VoidCallback onTap;

  const ZenCheckboxWidget({
    super.key,
    required this.isChecked,
    required this.onTap,
  });

  @override
  State<ZenCheckboxWidget> createState() => _ZenCheckboxWidgetState();
}

class _ZenCheckboxWidgetState extends State<ZenCheckboxWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = ZenThemeService.instance;
    final accent = widget.isChecked ? theme.current.green : theme.accentColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 6.0),
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: _isHovered ? accent.withValues(alpha: 0.25) : Colors.transparent,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Icon(
            widget.isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
            size: 18.0,
            color: accent,
          ),
        ),
      ),
    );
  }
}

class ZenMarkdownEditingController extends mel.MarkdownEditingController {
  final void Function(String targetNote)? onWikiLinkTap;
  final void Function(int lineOffset, bool currentChecked)? onTaskToggleAtOffset;

  ZenMarkdownEditingController({
    super.text,
    super.onLinkTap,
    super.onImageTap,
    super.imageHeightLines = 5,
    this.onWikiLinkTap,
    this.onTaskToggleAtOffset,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final theme = ZenThemeService.instance;
    final font = theme.fontFamily == 'System Default' ? null : theme.fontFamily;

    final baseStyle = (style ?? const TextStyle()).copyWith(
      color: theme.current.fg,
      fontSize: theme.fontSize,
      fontFamily: font,
      height: 1.6,
    );

    return TextSpan(
      style: baseStyle,
      children: _parseTextToSpans(text, baseStyle, theme, 0),
    );
  }



  List<InlineSpan> _parseTextToSpans(String rawText, TextStyle baseStyle, ZenThemeService theme, [int textOffset = 0]) {
    final List<InlineSpan> spans = [];

    final cursorOffset = selection.baseOffset;
    int activeLineStart = -1;
    int activeLineEnd = -1;
    if (cursorOffset >= 0 && cursorOffset <= text.length) {
      final searchOffset = (cursorOffset > 0 && cursorOffset < text.length && text[cursorOffset] == '\n')
          ? cursorOffset - 1
          : (cursorOffset == text.length && text.isNotEmpty ? text.length - 1 : cursorOffset);
      final start = text.lastIndexOf('\n', searchOffset.clamp(0, text.isNotEmpty ? text.length - 1 : 0));
      activeLineStart = start == -1 ? 0 : start + 1;
      final end = text.indexOf('\n', activeLineStart);
      activeLineEnd = end == -1 ? text.length : end;
    }

    bool isLineActive(int offset) {
      if (activeLineStart == -1) return false;
      return offset >= activeLineStart && offset <= activeLineEnd;
    }

    final RegExp syntaxRegex = RegExp(
      r'(\u200B)|'                                                       // G1: Virtual newline marker (from base class image spacing)
      r'(^|\r?\n)([ \t]*(#{1,6})\s+([^\r\n]*))|'                       // G2..G5: Headings
      r'(\[\[([^\]\|]+)(?:\|([^\]]+))?\]\])|'                         // G6..G8: WikiLink
      r'(==(.*?)==)|'                                                  // G9, G10: Highlight
      r'(~~(.*?)~~)|'                                                  // G11, G12: Strikethrough
      r'(\u2705\s*\d{4}-\d{2}-\d{2})|'                                 // G13: Date Tag
      r'(^|\r?\n)((?:[ \t]*\|[^\r\n]*\|[ \t]*(?:\r?\n|$))+)|'          // G14, G15: Multi-line Table Block
      r'(^|\r?\n)([ \t]*(?:[\*\-\+]\s+)?\[([ xX])\])([^\r\n]*)|'        // G16..G19: Task Checkbox
      r'(^|\r?\n)([ \t]*>\s*\[!([A-Za-z0-9_\-]+)\][ \t]*([^\r\n]*(?:\r?\n[ \t]*>[^\r\n]*)*))|' // G20..G23: Callout Multi-line Block
      r'(^|\r?\n)([ \t]*(?:---|\*\*\*|___)[ \t]*)(?=\r?\n|$)|'          // G24, G25: Horizontal Divider Line (---)
      r'(\*\*([^\*\r\n]+)\*\*)|'                                       // G26, G27: Bold **text**
      r'(\*([^\*\r\n]+)\*)|'                                           // G28, G29: Italic *text*
      r'(^|\r?\n)([ \t]*```[A-Za-z0-9_\-]*[ \t]*)',                    // G30, G31: Codeblock delimiter
      multiLine: true,
    );

    int lastEnd = 0;

    for (final match in syntaxRegex.allMatches(rawText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: rawText.substring(lastEnd, match.start), style: baseStyle));
      }

      final fullMatch = match.group(0)!;
      final absMatchOffset = textOffset + match.start;
      final active = isLineActive(absMatchOffset);

      // 0. Virtual newline marker \u200B (injected by base class for image spacing)
      // Must be rendered as invisible to preserve character count without causing line breaks.
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1)!,
          style: const TextStyle(fontSize: 0.001, color: Colors.transparent, height: 0.001),
        ));
      }
      // 1. Headings (# H1 to ###### H6)
      else if (match.group(2) != null || match.group(3) != null) {
        final newlinePrefix = match.group(2) ?? '';
        final hashes = match.group(4) ?? '#';
        final headingText = match.group(5) ?? '';
        final level = hashes.length.clamp(1, 6);

        if (newlinePrefix.isNotEmpty) {
          spans.add(TextSpan(text: newlinePrefix, style: baseStyle));
        }

        final baseSize = baseStyle.fontSize ?? 16.0;
        final double multiplier;
        switch (level) {
          case 1:
            multiplier = 1.80;
            break;
          case 2:
            multiplier = 1.50;
            break;
          case 3:
            multiplier = 1.25;
            break;
          case 4:
            multiplier = 1.10;
            break;
          case 5:
            multiplier = 1.00;
            break;
          case 6:
            multiplier = 0.90;
            break;
          default:
            multiplier = 1.00;
        }

        final headingStyle = baseStyle.copyWith(
          color: theme.getHeadingColor(level),
          fontSize: baseSize * multiplier,
          fontWeight: level <= 2 ? FontWeight.w700 : FontWeight.w600,
          height: level == 1 ? 1.55 : 1.45,
          letterSpacing: level == 1 ? -0.5 : (level == 2 ? -0.3 : 0.0),
        );

        // G3 = entire heading line content (indent + hashes + spaces + headingText).
        // We split it: prefix = G3 up to (but not including) G5; G5 = headingText.
        // This ensures the prefix span has the EXACT raw character count.
        final fullHeadingLine = match.group(3) ?? '';
        final prefixLength = fullHeadingLine.length - headingText.length;
        final rawPrefix = fullHeadingLine.substring(0, prefixLength);

        spans.add(TextSpan(
          text: rawPrefix,
          style: headingStyle.copyWith(
            color: theme.current.purple.withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ));
        spans.add(TextSpan(text: headingText, style: headingStyle));
      }
      // 2. WikiLink [[Target Note]] or [[Target Note|Alias]]
      else if (match.group(6) != null) {
        final wikiStyle = baseStyle.copyWith(
          color: theme.current.purple,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        );
        final noteName = match.group(7) ?? '';
        final alias = match.group(8);
        final mutedStyle = wikiStyle.copyWith(color: theme.current.purple.withValues(alpha: 0.45));

        spans.add(TextSpan(text: '[[', style: mutedStyle));
        spans.add(TextSpan(text: noteName, style: alias != null ? mutedStyle : wikiStyle));
        if (alias != null) {
          spans.add(TextSpan(text: '|', style: mutedStyle));
          spans.add(TextSpan(text: alias, style: wikiStyle));
        }
        spans.add(TextSpan(text: ']]', style: mutedStyle));
      }
      // 3. Highlight ==text==
      else if (match.group(9) != null) {
        final highlightText = match.group(10) ?? '';
        final highlightStyle = baseStyle.copyWith(
          backgroundColor: theme.current.yellow.withValues(alpha: 0.35),
          color: theme.current.fg,
          fontWeight: FontWeight.w600,
        );
        final mutedStyle = highlightStyle.copyWith(color: theme.current.yellow.withValues(alpha: 0.45));

        spans.add(TextSpan(text: '==', style: mutedStyle));
        spans.add(TextSpan(text: highlightText, style: highlightStyle));
        spans.add(TextSpan(text: '==', style: mutedStyle));
      }
      // 4. Strikethrough ~~text~~
      else if (match.group(11) != null) {
        final strikeText = match.group(12) ?? '';
        final strikeStyle = baseStyle.copyWith(
          decoration: TextDecoration.lineThrough,
          color: theme.current.grey,
        );
        final mutedStyle = strikeStyle.copyWith(color: theme.current.grey.withValues(alpha: 0.45));

        spans.add(TextSpan(text: '~~', style: mutedStyle));
        spans.add(TextSpan(text: strikeText, style: strikeStyle));
        spans.add(TextSpan(text: '~~', style: mutedStyle));
      }
      // 5. Date Tag
      else if (match.group(13) != null) {
        final dateText = match.group(13) ?? '';
        spans.add(TextSpan(
          text: dateText,
          style: baseStyle.copyWith(
            color: theme.current.green,
            fontWeight: FontWeight.w600,
            fontFamily: 'JetBrainsMono',
          ),
        ));
      }
      // 6. Unified Obsidian Markdown Table Block
      else if (match.group(14) != null || match.group(15) != null) {
        final newlinePrefix = match.group(14) ?? '';
        final tableBlock = match.group(15) ?? '';

        if (newlinePrefix.isNotEmpty) {
          spans.add(TextSpan(text: newlinePrefix, style: baseStyle));
        }

        final lines = tableBlock.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
        final blockStartOffset = absMatchOffset + newlinePrefix.length;
        final blockEndOffset = blockStartOffset + tableBlock.length;

        // Hidden text preserves character positions but must be 1 shorter
        // because the WidgetSpan below occupies 1 char slot in Flutter's model.
        // Total: hidden(N-1) + WidgetSpan(1) = N chars = tableBlock.length ✓
        final hiddenTableText = tableBlock.replaceAll('\r', '\u200B').replaceAll('\n', '\u200B');
        if (hiddenTableText.length > 1) {
          spans.add(TextSpan(
            text: hiddenTableText.substring(0, hiddenTableText.length - 1),
            style: const TextStyle(fontSize: 0.001, color: Colors.transparent, height: 0.001),
          ));
        }

        final List<List<String>> tableMatrix = [];
        bool hasHeader = false;

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('---')) {
            hasHeader = true;
            continue;
          }
          final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
          if (cells.isNotEmpty) {
            tableMatrix.add(cells);
          }
        }

        if (tableMatrix.isNotEmpty) {
          // WidgetSpan replaces the last character of tableBlock (1 char slot).
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: ZenObsidianTableWidget(
              tableMatrix: tableMatrix,
              hasHeader: hasHeader,
              theme: theme,
              baseStyle: baseStyle,
              onAddColumn: () => _insertTableColumn(blockStartOffset, blockEndOffset, tableBlock),
              onAddRow: () => _insertTableRow(blockStartOffset, blockEndOffset, tableBlock),
              onToggleTaskCell: (r, c, checked) => _toggleTableTaskCell(blockStartOffset, blockEndOffset, tableBlock, r, c, checked),
              onCellEdited: (r, c, newText) => _updateTableCellText(blockStartOffset, blockEndOffset, tableBlock, r, c, newText),
            ),
          ));
        } else {
          // No valid table rows — emit the remaining hidden char
          spans.add(TextSpan(
            text: hiddenTableText.substring(hiddenTableText.length - 1),
            style: const TextStyle(fontSize: 0.001, color: Colors.transparent, height: 0.001),
          ));
        }
      }
      // 7. Task Checkbox (- [ ] or - [x])
      else if (match.group(16) != null || match.group(17) != null) {
        final newlinePrefix = match.group(16) ?? '';
        final isDone = (match.group(18) ?? '').toLowerCase() == 'x';
        final taskText = match.group(19) ?? '';
        final matchStartOffset = textOffset + match.start + newlinePrefix.length;

        if (newlinePrefix.isNotEmpty) {
          spans.add(TextSpan(text: newlinePrefix, style: baseStyle));
        }

        final checkboxPrefix = match.group(17) ?? '';
        // checkboxPrefix is e.g. "- [x]" or "  * [ ]".
        // The WidgetSpan counts as exactly 1 char in Flutter's text model.
        // We assign it to the '[' character. Everything before '[' is rendered
        // as a visible TextSpan; 'x]' or ' ]' after it is hidden.
        // Total chars = beforeBracket + WidgetSpan(1) + afterBracket = len(checkboxPrefix) ✓
        final bracketIdx = checkboxPrefix.lastIndexOf('[');
        final beforeBracket = bracketIdx >= 0 ? checkboxPrefix.substring(0, bracketIdx) : checkboxPrefix;
        final afterBracket = bracketIdx >= 0 ? checkboxPrefix.substring(bracketIdx + 1) : '';

        if (beforeBracket.isNotEmpty) {
          spans.add(TextSpan(text: beforeBracket, style: baseStyle));
        }

        // WidgetSpan occupies exactly 1 char slot (replaces the '[' in the raw text).
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: ZenCheckboxWidget(
            isChecked: isDone,
            onTap: () {
              if (onTaskToggleAtOffset != null) {
                onTaskToggleAtOffset!(matchStartOffset, isDone);
              }
            },
          ),
        ));

        // Hide the rest of the bracket syntax ("x]" or " ]") — still counted in offset.
        if (afterBracket.isNotEmpty) {
          spans.add(TextSpan(
            text: afterBracket,
            style: const TextStyle(fontSize: 0.001, color: Colors.transparent),
          ));
        }

        final taskStyle = isDone
            ? baseStyle.copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: theme.current.grey,
                color: theme.current.fg.withValues(alpha: 0.6),
              )
            : baseStyle;

        if (taskText.isNotEmpty) {
          final textOffsetForTask = matchStartOffset + checkboxPrefix.length;
          spans.addAll(_parseTextToSpans(taskText, taskStyle, theme, textOffsetForTask));
        }
      }
      // 8. Full Multi-line Obsidian Callout Block (> [!NOTE] Title \n > Body)
      else if (match.group(20) != null || match.group(21) != null) {
        final newlinePrefix = match.group(20) ?? '';
        final fullCalloutText = match.group(21) ?? '';
        final calloutType = (match.group(22) ?? 'NOTE').toUpperCase();
        final rawCalloutContent = match.group(23) ?? '';

        if (newlinePrefix.isNotEmpty) {
          spans.add(TextSpan(text: newlinePrefix, style: baseStyle));
        }

        final blockStartOffset = absMatchOffset + newlinePrefix.length;
        final blockEndOffset = blockStartOffset + fullCalloutText.length;
        final isBlockActive = (activeLineStart >= blockStartOffset && activeLineStart <= blockEndOffset);

        Color calloutColor;
        IconData calloutIcon;
        switch (calloutType) {
          case 'WARNING':
          case 'CAUTION':
            calloutColor = theme.current.red;
            calloutIcon = Icons.warning_amber_rounded;
            break;
          case 'TIP':
          case 'HINT':
            calloutColor = theme.current.aqua;
            calloutIcon = Icons.water_drop_outlined;
            break;
          case 'IMPORTANT':
          case 'DANGER':
            calloutColor = theme.current.orange;
            calloutIcon = Icons.local_fire_department_outlined;
            break;
          case 'SUCCESS':
          case 'CHECK':
            calloutColor = theme.current.green;
            calloutIcon = Icons.check_circle_outline;
            break;
          case 'INFO':
          case 'NOTE':
          default:
            calloutColor = theme.current.blue;
            calloutIcon = Icons.edit_note_rounded;
            break;
        }

        final calloutStyle = baseStyle.copyWith(
          color: calloutColor,
          fontWeight: FontWeight.bold,
        );

        if (isBlockActive) {
          spans.add(TextSpan(text: fullCalloutText, style: calloutStyle));
        } else {
          // Hidden text is 1 shorter because WidgetSpan occupies 1 char slot.
          // Total: hidden(N-1) + WidgetSpan(1) = N chars = fullCalloutText.length ✓
          if (fullCalloutText.length > 1) {
            spans.add(TextSpan(
              text: fullCalloutText.substring(0, fullCalloutText.length - 1),
              style: const TextStyle(fontSize: 0.001, color: Colors.transparent),
            ));
          }

          final contentLines = rawCalloutContent.split('\n');
          final headerTitle = contentLines.isNotEmpty ? contentLines[0].trim() : '';
          final bodyLines = contentLines.length > 1
              ? contentLines.sublist(1).map((l) => l.replaceFirst(RegExp(r'^[ \t]*>\s?'), '')).join('\n')
              : '';

          final displayTitle = headerTitle.isNotEmpty
              ? headerTitle
              : (calloutType.substring(0, 1) + calloutType.substring(1).toLowerCase());

          // WidgetSpan replaces the last character of fullCalloutText (1 char slot).
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: calloutColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: calloutColor.withValues(alpha: 0.3), width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(calloutIcon, size: 18.0, color: calloutColor),
                      const SizedBox(width: 8.0),
                      Text(
                        displayTitle,
                        style: TextStyle(
                          color: calloutColor,
                          fontWeight: FontWeight.bold,
                          fontSize: (baseStyle.fontSize ?? 16.0) * 0.95,
                        ),
                      ),
                    ],
                  ),
                  if (bodyLines.isNotEmpty) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      bodyLines,
                      style: TextStyle(
                        color: theme.current.fg,
                        fontSize: (baseStyle.fontSize ?? 16.0) * 0.9,
                        height: 1.45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ));
        }
      }
      // 9. Horizontal Divider Line (---)
      else if (match.group(24) != null || match.group(25) != null) {
        final newlinePrefix = match.group(24) ?? '';
        final dividerText = match.group(25) ?? '';

        if (newlinePrefix.isNotEmpty) {
          spans.add(TextSpan(text: newlinePrefix, style: baseStyle));
        }

        if (active) {
          spans.add(TextSpan(
            text: dividerText,
            style: baseStyle.copyWith(
              color: theme.current.purple,
              fontWeight: FontWeight.bold,
            ),
          ));
        } else {
          // Hidden text is 1 shorter because WidgetSpan occupies 1 char slot.
          // Total: hidden(N-1) + WidgetSpan(1) = N chars = dividerText.length ✓
          if (dividerText.length > 1) {
            spans.add(TextSpan(
              text: dividerText.substring(0, dividerText.length - 1),
              style: const TextStyle(fontSize: 0.001, color: Colors.transparent),
            ));
          }
          // WidgetSpan replaces the last character of dividerText (1 char slot).
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12.0),
              height: 1.5,
              color: theme.current.bg2,
            ),
          ));
        }
      }
      // 10. Bold **text**
      else if (match.group(26) != null) {
        final boldText = match.group(27) ?? '';
        final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);
        final mutedStyle = boldStyle.copyWith(color: theme.current.grey.withValues(alpha: 0.45));

        spans.add(TextSpan(text: '**', style: mutedStyle));
        spans.add(TextSpan(text: boldText, style: boldStyle));
        spans.add(TextSpan(text: '**', style: mutedStyle));
      }
      // 11. Italic *text*
      else if (match.group(28) != null) {
        final italicText = match.group(29) ?? '';
        final italicStyle = baseStyle.copyWith(fontStyle: FontStyle.italic);
        final mutedStyle = italicStyle.copyWith(color: theme.current.grey.withValues(alpha: 0.45));

        spans.add(TextSpan(text: '*', style: mutedStyle));
        spans.add(TextSpan(text: italicText, style: italicStyle));
        spans.add(TextSpan(text: '*', style: mutedStyle));
      }
      // 12. Code block delimiter line (```)
      else if (match.group(30) != null || match.group(31) != null) {
        final newlinePrefix = match.group(30) ?? '';
        final codeLine = match.group(31) ?? '';
        final lang = codeLine.replaceAll('```', '').trim();

        if (newlinePrefix.isNotEmpty) {
          spans.add(TextSpan(text: newlinePrefix, style: baseStyle));
        }

        final codeBlockStyle = baseStyle.copyWith(
          fontFamily: 'JetBrainsMono',
          color: theme.codeColor,
          backgroundColor: theme.codeBgColor,
        );

        if (active) {
          spans.add(TextSpan(text: codeLine, style: codeBlockStyle.copyWith(fontWeight: FontWeight.bold)));
        } else {
          // Hidden text is 1 shorter because WidgetSpan occupies 1 char slot.
          // Total: hidden(N-1) + WidgetSpan(1) = N chars = codeLine.length ✓
          if (codeLine.length > 1) {
            spans.add(TextSpan(
              text: codeLine.substring(0, codeLine.length - 1),
              style: const TextStyle(fontSize: 0.001, color: Colors.transparent),
            ));
          }
          // WidgetSpan replaces the last character of codeLine (1 char slot).
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              margin: const EdgeInsets.only(top: 6.0, bottom: 2.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: theme.current.bg2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6.0)),
                border: Border.all(color: theme.current.bg2, width: 1.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code_rounded, size: 14.0, color: theme.accentColor),
                      const SizedBox(width: 6.0),
                      Text(
                        lang.isEmpty ? 'CODE' : lang.toUpperCase(),
                        style: TextStyle(
                          color: theme.accentColor,
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.content_copy_rounded, size: 14.0, color: theme.current.grey),
                ],
              ),
            ),
          ));
        }
      } else {
        spans.add(TextSpan(text: fullMatch, style: baseStyle));
      }

      lastEnd = match.end;
    }

    if (lastEnd < rawText.length) {
      spans.add(TextSpan(text: rawText.substring(lastEnd), style: baseStyle));
    }

    return spans;
  }

  void _insertTableColumn(int blockStartOffset, int blockEndOffset, String tableBlock) {
    final rawLines = tableBlock.split('\n');
    final newLines = <String>[];
    bool headerDone = false;

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains('---')) {
        headerDone = true;
        final lastPipeIndex = line.lastIndexOf('|');
        if (lastPipeIndex != -1) {
          newLines.add('${line.substring(0, lastPipeIndex)}| --- |${line.substring(lastPipeIndex + 1)}');
        } else {
          newLines.add('$line | --- |');
        }
      } else if (!headerDone && i == 0) {
        final lastPipeIndex = line.lastIndexOf('|');
        if (lastPipeIndex != -1) {
          newLines.add('${line.substring(0, lastPipeIndex)}| New Column |${line.substring(lastPipeIndex + 1)}');
        } else {
          newLines.add('$line | New Column |');
        }
      } else {
        final lastPipeIndex = line.lastIndexOf('|');
        if (lastPipeIndex != -1) {
          newLines.add('${line.substring(0, lastPipeIndex)}|  |${line.substring(lastPipeIndex + 1)}');
        } else {
          newLines.add('$line |  |');
        }
      }
    }

    final newTableBlockText = newLines.join('\n');
    final currentText = text;
    if (blockStartOffset + tableBlock.length <= currentText.length) {
      final newText = currentText.replaceRange(blockStartOffset, blockStartOffset + tableBlock.length, newTableBlockText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: blockStartOffset + newTableBlockText.length),
      );
    }
  }

  void _insertTableRow(int blockStartOffset, int blockEndOffset, String tableBlock) {
    final rawLines = tableBlock.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (rawLines.isEmpty) return;

    int colCount = 1;
    for (final line in rawLines) {
      if (!line.contains('---')) {
        final cells = line.split('|').map((c) => c.trim()).where((c) => c.isNotEmpty).toList();
        if (cells.length > colCount) {
          colCount = cells.length;
        }
      }
    }

    final newRowBuffer = StringBuffer('|');
    for (int i = 0; i < colCount; i++) {
      newRowBuffer.write('  |');
    }

    rawLines.add(newRowBuffer.toString());
    final newTableBlockText = rawLines.join('\n');

    final currentText = text;
    if (blockStartOffset + tableBlock.length <= currentText.length) {
      final newText = currentText.replaceRange(blockStartOffset, blockStartOffset + tableBlock.length, newTableBlockText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: blockStartOffset + newTableBlockText.length),
      );
    }
  }

  void _toggleTableTaskCell(int blockStartOffset, int blockEndOffset, String tableBlock, int rowIndex, int colIndex, bool currentChecked) {
    final rawLines = tableBlock.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (rawLines.isEmpty) return;

    int dataRowCounter = 0;
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      if (line.contains('---')) continue;

      if (dataRowCounter == rowIndex) {
        final parts = line.split('|');
        int validCellCount = 0;
        for (int p = 0; p < parts.length; p++) {
          final trimmed = parts[p].trim();
          if (trimmed.isEmpty && (p == 0 || p == parts.length - 1)) continue;
          if (validCellCount == colIndex) {
            if (currentChecked) {
              parts[p] = parts[p].replaceFirst(RegExp(r'\[[xX]\]'), '[ ]');
            } else {
              parts[p] = parts[p].replaceFirst(RegExp(r'\[\s?\]'), '[x]');
            }
            rawLines[i] = parts.join('|');
            break;
          }
          validCellCount++;
        }
        break;
      }
      dataRowCounter++;
    }

    final newTableBlockText = rawLines.join('\n');
    final currentText = text;
    if (blockStartOffset + tableBlock.length <= currentText.length) {
      final newText = currentText.replaceRange(blockStartOffset, blockStartOffset + tableBlock.length, newTableBlockText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: blockStartOffset + newTableBlockText.length),
      );
    }
  }

  void _updateTableCellText(int blockStartOffset, int blockEndOffset, String tableBlock, int rowIndex, int colIndex, String newCellText) {
    final rawLines = tableBlock.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (rawLines.isEmpty) return;

    int dataRowCounter = 0;
    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      if (line.contains('---')) continue;

      if (dataRowCounter == rowIndex) {
        final parts = line.split('|');
        int validCellCount = 0;
        for (int p = 0; p < parts.length; p++) {
          final trimmed = parts[p].trim();
          if (trimmed.isEmpty && (p == 0 || p == parts.length - 1)) continue;
          if (validCellCount == colIndex) {
            final existingPart = parts[p];
            if (existingPart.contains('[x]') || existingPart.contains('[X]') || existingPart.contains('[ ]')) {
              final isChecked = existingPart.contains('[x]') || existingPart.contains('[X]');
              final prefix = isChecked ? '[x] ' : '[ ] ';
              parts[p] = ' $prefix$newCellText ';
            } else {
              parts[p] = ' $newCellText ';
            }
            rawLines[i] = parts.join('|');
            break;
          }
          validCellCount++;
        }
        break;
      }
      dataRowCounter++;
    }

    final newTableBlockText = rawLines.join('\n');
    final currentText = text;
    if (blockStartOffset + tableBlock.length <= currentText.length) {
      final newText = currentText.replaceRange(blockStartOffset, blockStartOffset + tableBlock.length, newTableBlockText);
      value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: blockStartOffset + newTableBlockText.length),
      );
    }
  }
}

class ZenObsidianTableWidget extends StatefulWidget {
  final List<List<String>> tableMatrix;
  final bool hasHeader;
  final ZenThemeService theme;
  final TextStyle baseStyle;
  final VoidCallback onAddColumn;
  final VoidCallback onAddRow;
  final void Function(int rowIndex, int colIndex, bool currentChecked)? onToggleTaskCell;
  final void Function(int rowIndex, int colIndex, String newText)? onCellEdited;

  const ZenObsidianTableWidget({
    super.key,
    required this.tableMatrix,
    required this.hasHeader,
    required this.theme,
    required this.baseStyle,
    required this.onAddColumn,
    required this.onAddRow,
    this.onToggleTaskCell,
    this.onCellEdited,
  });

  @override
  State<ZenObsidianTableWidget> createState() => _ZenObsidianTableWidgetState();
}

class _ZenObsidianTableWidgetState extends State<ZenObsidianTableWidget> {
  bool _isTableHovered = false;
  bool _isAddColHovered = false;
  bool _isAddRowHovered = false;

  int? _editingRow;
  int? _editingCol;
  late TextEditingController _cellEditCtr;
  final FocusNode _cellFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _cellEditCtr = TextEditingController();
  }

  @override
  void dispose() {
    _cellEditCtr.dispose();
    _cellFocusNode.dispose();
    super.dispose();
  }

  void _startEditingCell(int rowIndex, int colIndex, String currentText) {
    final cleanText = currentText.replaceFirst(RegExp(r'\[[ xX]\]'), '').trim();
    setState(() {
      _editingRow = rowIndex;
      _editingCol = colIndex;
      _cellEditCtr.text = cleanText;
    });
    Future.microtask(() {
      if (mounted) {
        _cellFocusNode.requestFocus();
      }
    });
  }

  void _saveCellEdit() {
    if (_editingRow != null && _editingCol != null) {
      widget.onCellEdited?.call(_editingRow!, _editingCol!, _cellEditCtr.text);
      setState(() {
        _editingRow = null;
        _editingCol = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final baseStyle = widget.baseStyle;

    return MouseRegion(
      onEnter: (_) => setState(() => _isTableHovered = true),
      onExit: (_) => setState(() {
        _isTableHovered = false;
        _isAddColHovered = false;
        _isAddRowHovered = false;
      }),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8.0, bottom: 24.0, right: 32.0),
            decoration: BoxDecoration(
              color: theme.current.bg0,
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: theme.current.bg2, width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Table(
                defaultColumnWidth: const IntrinsicColumnWidth(),
                border: TableBorder.all(
                  color: theme.current.bg2.withValues(alpha: 0.6),
                  width: 1.0,
                ),
                children: List.generate(widget.tableMatrix.length, (rowIndex) {
                  final rowCells = widget.tableMatrix[rowIndex];
                  final isHeaderRow = (rowIndex == 0 && widget.hasHeader);
                  return TableRow(
                    decoration: BoxDecoration(
                      color: isHeaderRow ? theme.current.bg1 : Colors.transparent,
                    ),
                    children: List.generate(rowCells.length, (colIndex) {
                      final rawCellText = rowCells[colIndex];
                      final isEditing = (_editingRow == rowIndex && _editingCol == colIndex);
                      final isTask = rawCellText.contains('[x]') || rawCellText.contains('[X]') || rawCellText.contains('[ ]');
                      final isChecked = rawCellText.contains('[x]') || rawCellText.contains('[X]');
                      final cleanCellText = rawCellText
                          .replaceFirst(RegExp(r'\[[ xX]\]'), '')
                          .trim();

                      final cellTextStyle = TextStyle(
                        fontFamily: isHeaderRow ? 'JetBrainsMono' : null,
                        fontWeight: isHeaderRow ? FontWeight.bold : FontWeight.normal,
                        fontSize: (baseStyle.fontSize ?? 16.0) * 0.95,
                        color: theme.current.fg,
                      );

                      if (isEditing) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: TextField(
                            controller: _cellEditCtr,
                            focusNode: _cellFocusNode,
                            style: cellTextStyle,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                              fillColor: theme.current.bg1,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.0),
                                borderSide: BorderSide(color: theme.accentColor, width: 1.5),
                              ),
                            ),
                            onSubmitted: (_) => _saveCellEdit(),
                            onTapOutside: (_) => _saveCellEdit(),
                          ),
                        );
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: () => _startEditingCell(rowIndex, colIndex, rawCellText),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          child: isTask
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ZenCheckboxWidget(
                                      isChecked: isChecked,
                                      onTap: () {
                                        widget.onToggleTaskCell?.call(rowIndex, colIndex, isChecked);
                                      },
                                    ),
                                    if (cleanCellText.isNotEmpty)
                                      Flexible(
                                        child: Text(cleanCellText, style: cellTextStyle),
                                      ),
                                  ],
                                )
                              : Text(
                                  rawCellText,
                                  style: cellTextStyle,
                                ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ),

          // Right "+" Column Button & Tooltip
          if (_isTableHovered)
            Positioned(
              right: 0,
              top: 16.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isAddColHovered = true),
                    onExit: (_) => setState(() => _isAddColHovered = false),
                    child: GestureDetector(
                      onTap: widget.onAddColumn,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isAddColHovered ? theme.accentColor : theme.current.bg1,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: _isAddColHovered ? theme.accentColor : theme.current.bg2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: _isAddColHovered ? Colors.white : theme.current.fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),

                  if (_isAddColHovered)
                    Positioned(
                      top: 28.0,
                      left: -50.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: theme.current.bg0,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: theme.current.bg2, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Add column to the right',
                          style: TextStyle(
                            color: theme.current.fg,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Bottom "+" Row Button & Tooltip
          if (_isTableHovered)
            Positioned(
              left: 16.0,
              bottom: -2.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _isAddRowHovered = true),
                    onExit: (_) => setState(() => _isAddRowHovered = false),
                    child: GestureDetector(
                      onTap: widget.onAddRow,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _isAddRowHovered ? theme.accentColor : theme.current.bg1,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: _isAddRowHovered ? theme.accentColor : theme.current.bg2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: _isAddRowHovered ? Colors.white : theme.current.fg.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),

                  if (_isAddRowHovered)
                    Positioned(
                      top: 28.0,
                      left: -20.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: theme.current.bg0,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: theme.current.bg2, width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          'Add row to the bottom',
                          style: TextStyle(
                            color: theme.current.fg,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
