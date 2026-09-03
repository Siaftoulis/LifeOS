import re

path = 'client/lib/presentation/widgets/prayer_book/prayer_reader_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildReadingArea and _buildSection and _buildPrayerText
old_block_start = content.find('  Widget _buildReadingArea({')
old_block_end = content.find('  String _getDynamicTypeLabel(String type) {')

if old_block_start != -1 and old_block_end != -1:
    new_block = '''  Widget _buildReadingArea({
    required Color textColor,
    required Color rubricColor,
    required Color accentGold,
    required bool isDesktop,
    required bool isTablet,
  }) {
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 22.0 : 12.0);
    final isMobile = !isDesktop && !isTablet;

    return Stack(
      children: [
        SelectionArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(horizontalPadding, 14, horizontalPadding, 100),
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top ornament
                    Center(
                      child: Text(
                        '\\u2626',
                        style: TextStyle(
                          color: accentGold.withValues(alpha: 0.45),
                          fontSize: isMobile ? 20 : 24,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 18),
                    // Sections
                    ...List.generate(_service!.sections.length, (i) {
                      final section = _service!.sections[i];
                      return Padding(
                        key: _sectionKeys[i],
                        padding: EdgeInsets.only(bottom: isMobile ? 14 : 20),
                        child: _buildSection(
                          section,
                          i,
                          _service!.sections.length,
                          textColor,
                          rubricColor,
                          accentGold,
                          isMobile,
                        ),
                      );
                    }),
                    // Bottom ornament
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        '\\u2626',
                        style: TextStyle(
                          color: accentGold.withValues(alpha: 0.45),
                          fontSize: isMobile ? 20 : 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Floating compact auto-scroll pill
        Positioned(
          right: isMobile ? 12 : 16,
          bottom: isMobile ? 12 : 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleAutoScroll,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAutoScrolling
                      ? EverforestColors.red
                      : EverforestColors.green,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAutoScrolling
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: EverforestColors.bg0,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isAutoScrolling ? '\\u03a0\\u03b1\\u03cd\\u03c3\\u03b7' : '\\u039a\\u03cd\\u03bb\\u03b9\\u03c3\\u03b7',
                      style: const TextStyle(
                        color: EverforestColors.bg0,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
      PrayerSectionModel section,
      int index,
      int totalSections,
      Color textColor,
      Color rubricColor,
      Color accentGold,
      bool isMobile) {
    final isRubric = section.isRubric;
    final isDynamic = section.isDynamic;

    return Container(
      width: double.infinity,
      padding: isMobile
          ? const EdgeInsets.fromLTRB(14, 14, 14, 16)
          : const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: isDynamic
            ? accentGold.withValues(alpha: _isParchmentMode ? 0.08 : 0.05)
            : (_isParchmentMode
                ? Colors.black.withValues(alpha: 0.05)
                : EverforestColors.bg1.withValues(alpha: 0.45)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDynamic
              ? accentGold.withValues(alpha: 0.3)
              : (_isParchmentMode
                  ? Colors.black.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.06)),
          width: isDynamic ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          if (section.header.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: rubricColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rubricColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '\\u00a7 ${index + 1}',
                    style: TextStyle(
                      color: rubricColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    section.header,
                    style: TextStyle(
                      color: rubricColor,
                      fontSize: isMobile
                          ? (_fontSize * 0.86).clamp(13.0, 18.0)
                          : _fontSize * 0.9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                if (isDynamic) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: accentGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: accentGold, size: 10),
                        const SizedBox(width: 3),
                        Text(
                          _getDynamicTypeLabel(section.dynamicType),
                          style: TextStyle(
                            color: accentGold,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: isDynamic
                  ? accentGold.withValues(alpha: 0.18)
                  : (_isParchmentMode
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.06)),
            ),
            const SizedBox(height: 12),
          ],

          // Content
          _buildPrayerText(section.content, textColor, isRubric, rubricColor, isMobile),
        ],
      ),
    );
  }

  Widget _buildPrayerText(
      String content, Color textColor, bool isRubric, Color rubricColor, bool isMobile) {
    final paragraphs = content.split('\\n\\n');

    return RichText(
      text: TextSpan(
        children: paragraphs.map((para) {
          final trimmed = para.trim();
          if (trimmed.isEmpty) {
            return TextSpan(text: '\\n', style: TextStyle(fontSize: _fontSize * 0.5));
          }

          final lines = trimmed.split('\\n');
          final isSubHeader = lines.length == 1 &&
              trimmed.length < 75 &&
              !trimmed.endsWith('.') &&
              !trimmed.endsWith('\\u00b7') &&
              !trimmed.endsWith(')');

          if (isSubHeader && !isRubric) {
            return TextSpan(
              children: [
                const TextSpan(text: '\\n'),
                TextSpan(
                  text: trimmed,
                  style: TextStyle(
                    color: EverforestColors.yellow,
                    fontSize: _fontSize * 0.94,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    height: 1.5,
                    letterSpacing: 0.3,
                  ),
                ),
                const TextSpan(text: '\\n\\n'),
              ],
            );
          }

          // Parse lines within paragraph to highlight speakers and verse numbers
          final lineSpans = <InlineSpan>[];
          for (int li = 0; li < lines.length; li++) {
            final line = lines[li];
            final tline = line.trim();

            if (li > 0) {
              lineSpans.add(const TextSpan(text: '\\n'));
            }

            final speakerMatch = RegExp(r'^(\\u0399\\u0395\\u03a1\\u0395\\u03a5\\u03a3|\\u0394\\u0399\\u0391\\u039a\\u039f\\u039d\\u039f\\u03a3|\\u03a7\\u039f\\u03a1\\u039f\\u03a3|\\u0391\\u039d\\u0391\\u0393\\u039d\\u03a9\\u03a3\\u03a4\\u0397\\u03a3|\\u039b\\u0391\\u039f\\u03a3)(\\s*\\([^)]+\\))?:').firstMatch(tline);
            final verseMatch = RegExp(r"^(\\u03a3\\u03c4\\u03af\\u03c7\\.\\s*[^:\\n]+:|\\u03a3\\u03c4\\u03af\\u03c7\\u03bf\\u03b9[^:\\n]*:|\\u0394\\u03cc\\u03be\\u03b1\\s*\\u03a0\\u03b1\\u03c4\\u03c1\\u03af\\.\\.\\.|\\u039a\\u03b1\\u1f76\\s*\\u03bd\\u1fe6\\u03bd\\.\\.\\.|\\u0394\\u03cc\\u03be\\u03b1\\.\\.\\.|\\u03a3\\u03a4\\u0399\\u03a7\\u039f\\u039b\\u039f\\u0393\\u0399\\u0391\\s*[^:\\n]+:|\\u0397\\s*\\u03a5\\u03a0\\u0391\\u039a\\u039f\\u0397:|\\u039f\\u0399\\s*\\u0391\\u039d\\u0391\\u0392\\u0391\\u0398\\u039c\\u039f\\u0399|\\u03a4\\u039f\\s*\\u03a0\\u03a1\\u039f\\u039a\\u0395\\u0399\\u039c\\u0395\\u039d\\u039f\\u039d|\\u0391\\u03a0\\u039f\\u039b\\u03a5\\u03a4\\u0399\\u039a\\u0399[\\u0391\\u039f]\\u039d[^:\\n]*:|\\u039a\\u039f\\u039d\\u03a4\\u0391\\u039a\\u0399\\u039f\\u039d[^:\\n]*:|\\u039f\\s*\\u039f\\u0399\\u039a\\u039f\\u03a3:|\\u0395\\u039e\\u0391\\u03a0\\u039f\\u03a3\\u03a4\\u0395\\u0399\\u039b\\u0391\\u03a1\\u0399\\u039f\\u039d[^:\\n]*:|\\u0398\\u0395\\u039f\\u03a4\\u039f\\u039a\\u0399\\u039f\\u039d:|\\u1f49\\s*\\u0395\\u1f31\\u03c1\\u03bc\\u03cc\\u03c2:|\\u1f49\\s*\\u0395\\u03b9\\u03c1\\u03bc\\u03cc\\u03c2:|\\u039a\\u0391\\u0398\\u0399\\u03a3\\u039c\\u0391\\s*[^:\\n]+:|\\u1f68\\u03b4\\u1f74\\s*[^:\\n]+:)").firstMatch(tline);

            if (speakerMatch != null) {
              final spk = speakerMatch.group(0)!;
              final rest = tline.substring(spk.length);
              lineSpans.add(TextSpan(
                text: spk,
                style: TextStyle(
                  color: rubricColor,
                  fontSize: _fontSize * 0.88,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  letterSpacing: 0.4,
                ),
              ));
              if (rest.isNotEmpty) {
                lineSpans.add(TextSpan(
                  text: rest,
                  style: TextStyle(
                    color: isRubric ? rubricColor : textColor,
                    fontSize: isRubric ? _fontSize * 0.9 : _fontSize,
                    fontStyle: isRubric ? FontStyle.italic : FontStyle.normal,
                    fontFamily: 'serif',
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ));
              }
            } else if (verseMatch != null) {
              final vfx = verseMatch.group(0)!;
              final rest = tline.substring(vfx.length);
              lineSpans.add(TextSpan(
                text: vfx,
                style: TextStyle(
                  color: EverforestColors.aqua,
                  fontSize: _fontSize * 0.92,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ));
              if (rest.isNotEmpty) {
                lineSpans.add(TextSpan(
                  text: rest,
                  style: TextStyle(
                    color: isRubric ? rubricColor : textColor,
                    fontSize: isRubric ? _fontSize * 0.9 : _fontSize,
                    fontStyle: isRubric ? FontStyle.italic : FontStyle.normal,
                    fontFamily: 'serif',
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                ));
              }
            } else {
              lineSpans.add(TextSpan(
                text: line,
                style: TextStyle(
                  color: isRubric ? rubricColor : textColor,
                  fontSize: isRubric ? _fontSize * 0.9 : _fontSize,
                  fontStyle: isRubric ? FontStyle.italic : FontStyle.normal,
                  fontFamily: 'serif',
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ));
            }
          }

          lineSpans.add(const TextSpan(text: '\\n\\n'));
          return TextSpan(children: lineSpans);
        }).toList(),
      ),
    );
  }

'''
    updated = content[:old_block_start] + new_block + content[old_block_end:]
    with open(path, 'w', encoding='utf-8') as f:
        f.write(updated)
    print('Updated prayer_reader_screen.dart successfully!')
else:
    print('Could not find block delimiters in prayer_reader_screen.dart!')
