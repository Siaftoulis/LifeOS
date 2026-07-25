import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../theme/zen_theme_service.dart';

class ZenPreviewPanel extends StatelessWidget {
  final String markdownData;
  final void Function(String targetNote)? onWikiLinkTap;
  final void Function(int taskIndex, bool newValue)? onTaskToggle;

  const ZenPreviewPanel({
    super.key,
    required this.markdownData,
    this.onWikiLinkTap,
    this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ZenThemeService.instance;

    return AnimatedBuilder(
      animation: theme,
      builder: (context, _) {
        final colors = theme.current;
        final font = theme.fontFamily == 'System Default' ? null : theme.fontFamily;

        return Container(
          color: colors.bg0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Markdown(
            data: _preprocessCalloutsWikiLinksAndTasks(markdownData),
            selectable: false,
            onTapLink: (text, href, title) {
              if (href != null) {
                if (href.startsWith('wikilink://')) {
                  final target = Uri.decodeComponent(href.replaceFirst('wikilink://', ''));
                  if (onWikiLinkTap != null) {
                    onWikiLinkTap!(target);
                  }
                } else if (href.startsWith('task://')) {
                  final parts = href.replaceFirst('task://', '').split('/');
                  if (parts.length >= 2) {
                    final index = int.tryParse(parts[0]);
                    final nextVal = parts[1] == 'true';
                    if (index != null && onTaskToggle != null) {
                      onTaskToggle!(index, nextVal);
                    }
                  }
                }
              }
            },
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: colors.fg,
                fontFamily: font,
                fontSize: theme.fontSize,
                height: 1.6,
              ),
              h1: TextStyle(
                color: theme.getHeadingColor(1),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              h2: TextStyle(
                color: theme.getHeadingColor(2),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              h3: TextStyle(
                color: theme.getHeadingColor(3),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              h4: TextStyle(
                color: theme.getHeadingColor(4),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              h5: TextStyle(
                color: theme.getHeadingColor(5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              h6: TextStyle(
                color: theme.getHeadingColor(6),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              em: TextStyle(color: colors.fg, fontStyle: FontStyle.italic),
              strong: TextStyle(color: theme.boldColor, fontWeight: FontWeight.bold),
              del: TextStyle(color: colors.grey, decoration: TextDecoration.lineThrough),
              blockquote: TextStyle(color: colors.fg, fontStyle: FontStyle.normal, height: 1.5),
              blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              blockquoteDecoration: BoxDecoration(
                color: colors.bg1.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: theme.accentColor, width: 4)),
              ),
              code: TextStyle(
                color: theme.codeColor,
                backgroundColor: theme.codeBgColor,
                fontFamily: font ?? 'JetBrainsMono',
                fontSize: theme.fontSize * 0.9,
              ),
              codeblockDecoration: BoxDecoration(
                color: colors.bg1,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.bg2),
              ),
              tableHead: TextStyle(
                color: colors.fg,
                fontWeight: FontWeight.bold,
                fontFamily: font,
              ),
              tableBody: TextStyle(
                color: colors.fg,
                fontFamily: font,
              ),
              tableBorder: TableBorder.all(
                color: colors.bg2,
                width: 1,
              ),
              tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              listBullet: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.bg2, width: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _preprocessCalloutsWikiLinksAndTasks(String input) {
    int taskCount = 0;

    // 1. Task Checkboxes: - [ ] or - [x]
    // Preserve bullet list format "- " so items stack vertically as list items and apply strikethrough to completed tasks!
    final taskRegex = RegExp(r'^([ \t]*(?:[\*\-\+]\s+)?)\[([ xX])\]([^\n]*)', multiLine: true);
    String processed = input.replaceAllMapped(taskRegex, (match) {
      final prefix = match.group(1)!.trim().isEmpty ? '- ' : match.group(1)!;
      final isChecked = match.group(2)!.toLowerCase() == 'x';
      final restOfLine = match.group(3) ?? '';
      final currentIdx = taskCount++;
      final nextVal = !isChecked;
      final icon = isChecked ? '☑' : '☐';

      final trimmedRest = restOfLine.trim();
      final formattedRest = (isChecked && trimmedRest.isNotEmpty && !trimmedRest.startsWith('~~'))
          ? ' ~~$trimmedRest~~'
          : restOfLine;

      return '$prefix[$icon](task://$currentIdx/$nextVal)$formattedRest';
    });

    // 2. Obsidian Callouts > [!NOTE] Title
    final calloutRegex = RegExp(r'^[ \t]*>\s*\[!([A-Za-z]+)\][ \t]*(.*)$', multiLine: true);
    processed = processed.replaceAllMapped(calloutRegex, (match) {
      final type = match.group(1)!.toUpperCase();
      final title = match.group(2)!.trim();
      String icon;
      switch (type) {
        case 'WARNING':
        case 'CAUTION':
          icon = '⚠️';
          break;
        case 'TIP':
        case 'HINT':
          icon = '💡';
          break;
        case 'IMPORTANT':
        case 'DANGER':
          icon = '⚡';
          break;
        case 'INFO':
        case 'NOTE':
        default:
          icon = '📝';
          break;
      }
      final displayTitle = title.isEmpty ? type : title;
      return '> **$icon $displayTitle**\n>';
    });

    // 3. WikiLinks [[Note Title|Alias]] or [[Note Title]]
    final wikiRegex = RegExp(r'\[\[([^\]\|]+)(?:\|([^\]]+))?\]\]');
    processed = processed.replaceAllMapped(wikiRegex, (match) {
      final target = match.group(1)!.trim();
      final alias = match.group(2)?.trim() ?? target;
      final encoded = Uri.encodeComponent(target);
      return '**[$alias](wikilink://$encoded)**';
    });

    // 4. Highlights ==text==
    final highlightRegex = RegExp(r'==(.*?)==');
    processed = processed.replaceAllMapped(highlightRegex, (match) {
      final inner = match.group(1)!;
      return '**$inner**';
    });

    return processed;
  }
}
