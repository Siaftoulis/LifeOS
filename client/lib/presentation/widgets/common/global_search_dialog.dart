import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/search/global_search_service.dart';
import '../../../theme/everforest_colors.dart';

class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => const GlobalSearchDialog(),
    );
  }

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GlobalSearchService _service = GlobalSearchService.instance;

  SearchCategory _selectedCategory = SearchCategory.all;
  List<SearchResultItem> _results = [];
  bool _isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _performSearch('');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String text) async {
    setState(() => _isLoading = true);
    final items = await _service.search(text, category: _selectedCategory, context: context);
    if (mounted) {
      setState(() {
        _results = items;
        _isLoading = false;
        _selectedIndex = 0;
      });
    }
  }

  void _onCategoryChanged(SearchCategory cat) {
    setState(() => _selectedCategory = cat);
    _performSearch(_controller.text);
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_results.isNotEmpty) {
          setState(() {
            _selectedIndex = (_selectedIndex + 1) % _results.length;
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_results.isNotEmpty) {
          setState(() {
            _selectedIndex = (_selectedIndex - 1 + _results.length) % _results.length;
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_results.isNotEmpty && _selectedIndex < _results.length) {
          _selectItem(_results[_selectedIndex]);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
    }
  }

  void _selectItem(SearchResultItem item) {
    // Capture navigator and context before popping dialog
    final nav = Navigator.of(context);
    nav.pop();

    if (item.onAction != null) {
      // Small delay to ensure dialog unmounts cleanly
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentContext = nav.context;
        item.onAction!(currentContext);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKey,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          width: 720,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: EverforestColors.bg1.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EverforestColors.green.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Header Input
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: EverforestColors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          hintText: 'Αναζήτηση καρτελών, ακολουθιών, μουσικής, σημειώσεων... (Ctrl+K)',
                          hintStyle: TextStyle(color: EverforestColors.grey, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _performSearch,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.green),
                      )
                    else if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, color: EverforestColors.grey, size: 18),
                        onPressed: () {
                          _controller.clear();
                          _performSearch('');
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: EverforestColors.bg2),
              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('Όλα (All)', SearchCategory.all),
                    _buildFilterChip('Καρτέλες (Tabs)', SearchCategory.modules),
                    _buildFilterChip('Προσευχητάρι (Prayers)', SearchCategory.prayers),
                    _buildFilterChip('Μουσική (Music)', SearchCategory.music),
                    _buildFilterChip('Σημειώσεις (Notes)', SearchCategory.notes),
                    _buildFilterChip('Gallery', SearchCategory.gallery),
                    _buildFilterChip('Ρυθμίσεις (Settings)', SearchCategory.settings),
                  ],
                ),
              ),
              const Divider(height: 1, color: EverforestColors.bg2),
              // Results List
              Expanded(
                child: _results.isEmpty && !_isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Δεν βρέθηκαν αποτελέσματα για την αναζήτησή σας',
                            style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () => _selectItem(item),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? EverforestColors.green.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? EverforestColors.green.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: item.accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(item.icon, color: item.accentColor, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: const TextStyle(
                                                  color: EverforestColors.fg,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: item.accentColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: item.accentColor.withValues(alpha: 0.3),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Text(
                                                item.badgeLabel,
                                                style: TextStyle(
                                                  color: item.accentColor,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          item.subtitle,
                                          style: const TextStyle(
                                            color: EverforestColors.grey,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isSelected)
                                    const Icon(
                                      Icons.keyboard_return_rounded,
                                      color: EverforestColors.green,
                                      size: 16,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Footer Shortcut Hints
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: EverforestColors.bg0,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: const Row(
                  children: [
                    Text('↑↓ Πλοήγηση', style: TextStyle(color: EverforestColors.grey, fontSize: 11)),
                    SizedBox(width: 14),
                    Text('↵ Άνοιγμα / Μετάβαση', style: TextStyle(color: EverforestColors.grey, fontSize: 11)),
                    SizedBox(width: 14),
                    Text('esc Κλείσιμο', style: TextStyle(color: EverforestColors.grey, fontSize: 11)),
                    Spacer(),
                    Text('LifeOS Command Palette', style: TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchCategory category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? EverforestColors.bg0 : EverforestColors.fg,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => _onCategoryChanged(category),
        backgroundColor: EverforestColors.bg0,
        selectedColor: EverforestColors.green,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? EverforestColors.green : EverforestColors.bg2,
          ),
        ),
      ),
    );
  }
}
