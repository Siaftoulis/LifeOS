path = 'client/lib/presentation/widgets/prayer_book/psalter_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

settings_and_build = '''  void _openSettingsSheet(BuildContext context, Color fgColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: fgColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '\\u03a1\\u03c5\\u03b8\\u03bc\\u03af\\u03c3\\u03b5\\u03b9\\u03c2 \\u0391\\u03bd\\u03ac\\u03b3\\u03bd\\u03c9\\u03c3\\u03b7\\u03c2',
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 18),
              // Theme Mode
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\\u0398\\u03ad\\u03bc\\u03b1 \\u03a0\\u03b5\\u03c1\\u03b3\\u03b1\\u03bc\\u03b7\\u03bd\\u03ae\\u03c2',
                    style: TextStyle(color: fgColor, fontSize: 14),
                  ),
                  Switch.adaptive(
                    value: _isParchment,
                    activeColor: EverforestColors.yellow,
                    onChanged: (v) {
                      setState(() => _isParchment = v);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Font Size
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\\u039c\\u03ad\\u03b3\\u03b5\\u03b8\\u03bf\\u03c2 \\u0393\\u03c1\\u03b1\\u03bc\\u03bc\\u03b1\\u03c4\\u03bf\\u03c3\\u03b5\\u03b9\\u03c1\\u03ac\\u03c2',
                    style: TextStyle(color: fgColor, fontSize: 14),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline_rounded, color: fgColor),
                        onPressed: _fontSize > 13
                            ? () {
                                setState(() => _fontSize -= 1.5);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                      Text(
                        '${_fontSize.toStringAsFixed(1)}',
                        style: TextStyle(color: fgColor, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline_rounded, color: fgColor),
                        onPressed: _fontSize < 28
                            ? () {
                                setState(() => _fontSize += 1.5);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final bgColor = _isParchment ? const Color(0xFFF9F5EC) : EverforestColors.bg0;
    final fgColor = _isParchment ? const Color(0xFF2C3E35) : EverforestColors.fg;
    final rubricColor = _isParchment ? const Color(0xFF8B2500) : EverforestColors.red;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: _isParchment ? const Color(0xFFF2EBD9) : EverforestColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: fgColor),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(color: fgColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: '\\u0391\\u03bd\\u03b1\\u03b6\\u03ae\\u03c4\\u03b7\\u03c3\\u03b7 \\u03c3\\u03c4\\u03bf\\u03c5\\u03c2 150 \\u03a8\\u03b1\\u03bb\\u03bc\\u03bf\\u03cd\\u03c2...',
                  hintStyle: TextStyle(color: fgColor.withValues(alpha: 0.5), fontSize: 13),
                  border: InputBorder.none,
                ),
                onChanged: (q) => setState(() => _searchQuery = q.trim().toLowerCase()),
              )
            : Text(
                '\\u03a8\\u03b1\\u03bb\\u03c4\\u03ae\\u03c1\\u03b9\\u03bf\\u03bd \\u03c4\\u03bf\\u03c5 \\u0394\\u03b1\\u03c5\\u0390\\u03b4',
                style: TextStyle(color: fgColor, fontWeight: FontWeight.bold, fontSize: isMobile ? 15 : 16),
              ),
        actions: [
          IconButton(
            visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            icon: Icon(_showSearch ? Icons.close_rounded : Icons.search_rounded, color: fgColor, size: 20),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
          IconButton(
            visualDensity: isMobile ? VisualDensity.compact : VisualDensity.standard,
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            icon: Icon(Icons.translate_rounded, color: _showTranslation ? EverforestColors.aqua : fgColor, size: 20),
            tooltip: _showTranslation ? '\\u0391\\u03c0\\u03cc\\u03ba\\u03c1\\u03c5\\u03c8\\u03b7 \\u039c\\u03b5\\u03c4\\u03ac\\u03c6\\u03c1\\u03b1\\u03c3\\u03b7\\u03c2' : '\\u0395\\u03bc\\u03c6\\u03ac\\u03bd\\u03b9\\u03c3\\u03b7 \\u039c\\u03b5\\u03c4\\u03ac\\u03c6\\u03c1\\u03b1\\u03c3\\u03b7\\u03c2',
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          if (isMobile)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              icon: Icon(Icons.tune_rounded, color: fgColor, size: 20),
              tooltip: '\\u03a1\\u03c5\\u03b8\\u03bc\\u03af\\u03c3\\u03b5\\u03b9\\u03c2',
              onPressed: () => _openSettingsSheet(context, fgColor),
            )
          else ...[
            IconButton(
              icon: Icon(_isParchment ? Icons.dark_mode_rounded : Icons.menu_book_rounded, color: fgColor, size: 20),
              tooltip: '\\u0395\\u03bd\\u03b1\\u03bb\\u03bb\\u03b1\\u03b3\\u03ae \\u03b8\\u03ad\\u03bc\\u03b1\\u03c4\\u03bf\\u03c2',
              onPressed: () => setState(() => _isParchment = !_isParchment),
            ),
            IconButton(
              icon: Icon(Icons.text_increase_rounded, color: fgColor, size: 20),
              tooltip: '\\u0391\\u03cd\\u03be\\u03b7\\u03c3\\u03b7 \\u03b3\\u03c1\\u03b1\\u03bc\\u03bc\\u03b1\\u03c4\\u03bf\\u03c3\\u03b5\\u03b9\\u03c1\\u03ac\\u03c2',
              onPressed: () {
                if (_fontSize < 28) setState(() => _fontSize += 1.5);
              },
            ),
            IconButton(
              icon: Icon(Icons.text_decrease_rounded, color: fgColor, size: 20),
              tooltip: '\\u039c\\u03b5\\u03af\\u03c9\\u03c3\\u03b7 \\u03b3\\u03c1\\u03b1\\u03bc\\u03bc\\u03b1\\u03c4\\u03bf\\u03c3\\u03b5\\u03b9\\u03c1\\u03ac\\u03c2',
              onPressed: () {
                if (_fontSize > 13) setState(() => _fontSize -= 1.5);
              },
            ),
          ],
        ],
      ),'''

# Find build method in psalter_screen.dart
build_idx = content.find('  @override\n  Widget build(BuildContext context) {')
appbar_end_idx = content.find('      body: _isLoading')

if build_idx != -1 and appbar_end_idx != -1:
    content = content[:build_idx] + settings_and_build + '\n' + content[appbar_end_idx:]

# Now update the ListView padding and Psalm Container in psalter_screen.dart
content = content.replace(
    'padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),',
    'padding: EdgeInsets.fromLTRB(isMobile ? 12 : 20, 14, isMobile ? 12 : 20, 90),'
)

old_psalm_container = '''                                return Container(
                                  key: _psalmKeys[psalm.number],
                                  margin: const EdgeInsets.only(bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: ['''

new_psalm_container = '''                                return Container(
                                  key: _psalmKeys[psalm.number],
                                  margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
                                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                                  decoration: BoxDecoration(
                                    color: _isParchment
                                        ? Colors.black.withValues(alpha: 0.04)
                                        : EverforestColors.bg1.withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isParchment
                                          ? Colors.black.withValues(alpha: 0.08)
                                          : Colors.white.withValues(alpha: 0.06),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: ['''

content = content.replace(old_psalm_container, new_psalm_container)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated psalter_screen.dart successfully!')
