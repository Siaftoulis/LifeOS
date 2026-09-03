import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/repositories/prayer_repository.dart';
import '../../../theme/everforest_colors.dart';

class PrayerReaderScreen extends StatefulWidget {
  const PrayerReaderScreen({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    this.date,
  });

  final String serviceId;
  final String serviceTitle;
  final DateTime? date;

  @override
  State<PrayerReaderScreen> createState() => _PrayerReaderScreenState();
}

class _PrayerReaderScreenState extends State<PrayerReaderScreen> {
  double _fontSize = 17.0;
  bool _isParchmentMode = false;
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 1.0;
  Timer? _scrollTimer;
  final ScrollController _scrollController = ScrollController();
  PrayerServiceModel? _service;
  bool _isLoading = true;
  int _activeSectionIndex = 0;
  final Map<int, GlobalKey> _sectionKeys = {};
  bool _desktopSidebarOpen = true;
  int _selectedSaintIdx = 0;
  bool _isProgrammaticScrolling = false;
  Timer? _programmaticScrollTimer;

  static const _maxContentWidth = 760.0;
  static const _sidebarWidth = 220.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadService(0);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _programmaticScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isProgrammaticScrolling || !_scrollController.hasClients || _service == null) return;
    for (int i = _service!.sections.length - 1; i >= 0; i--) {
      final key = _sectionKeys[i];
      if (key?.currentContext != null) {
        final box = key!.currentContext!.findRenderObject() as RenderBox?;
        if (box != null) {
          final pos = box.localToGlobal(Offset.zero, ancestor: null);
          if (pos.dy <= 140) {
            if (_activeSectionIndex != i) {
              setState(() => _activeSectionIndex = i);
            }
            break;
          }
        }
      }
    }
  }

  Future<void> _loadService([int saintIdx = 0]) async {
    final svc = await PrayerRepository.instance
        .fetchService(widget.serviceId, widget.date, saintIdx);
    if (mounted && svc != null) {
      _sectionKeys.clear();
      for (int i = 0; i < svc.sections.length; i++) {
        _sectionKeys[i] = GlobalKey();
      }
      setState(() {
        _service = svc;
        _selectedSaintIdx = svc.selectedCommemorationIndex;
        _isLoading = false;
        _activeSectionIndex = 0;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleAutoScroll() {
    setState(() => _isAutoScrolling = !_isAutoScrolling);
    if (_isAutoScrolling) {
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (_scrollController.hasClients) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final current = _scrollController.offset;
          if (current < maxScroll) {
            _scrollController.jumpTo(current + _autoScrollSpeed);
          } else {
            _scrollTimer?.cancel();
            setState(() => _isAutoScrolling = false);
          }
        }
      });
    } else {
      _scrollTimer?.cancel();
    }
  }

  void _scrollToSection(int index) {
    final key = _sectionKeys[index];
    if (key?.currentContext != null) {
      _programmaticScrollTimer?.cancel();
      setState(() {
        _activeSectionIndex = index;
        _isProgrammaticScrolling = true;
      });
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        alignment: 0.05,
      ).then((_) {
        _programmaticScrollTimer = Timer(const Duration(milliseconds: 120), () {
          if (mounted) {
            _isProgrammaticScrolling = false;
          }
        });
      });
    }
  }

  void _openMobileToc(BuildContext context, Color textColor, Color accentGold, Color sidebarBg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: sidebarBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Icon(Icons.toc_rounded, color: accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ΠΕΡΙΕΧΟΜΕΝΑ',
                      style: TextStyle(
                        color: accentGold,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_service?.sections.length ?? 0} Ενότητες',
                      style: TextStyle(
                        color: EverforestColors.grey.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _service?.sections.length ?? 0,
                  itemBuilder: (context, index) {
                    final section = _service!.sections[index];
                    if (section.header.isEmpty) return const SizedBox.shrink();
                    final isActive = _activeSectionIndex == index;
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _scrollToSection(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        color: isActive
                            ? accentGold.withValues(alpha: 0.14)
                            : Colors.transparent,
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? accentGold
                                    : Colors.transparent,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                style: TextStyle(
                                  color: isActive
                                      ? accentGold
                                      : textColor.withValues(alpha: 0.8),
                                  fontSize: 13.5,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                child: Text(
                                  section.header,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
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
      },
    );
  }

  void _openSettingsSheet(BuildContext context, Color textColor, Color accentGold, Color sidebarBg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: sidebarBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ρυθμίσεις Ανάγνωσης',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Theme Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Λειτουργία Περγαμηνής',
                          style: TextStyle(color: EverforestColors.fg, fontSize: 13.5),
                        ),
                        Switch(
                          value: _isParchmentMode,
                          activeThumbColor: EverforestColors.yellow,
                          onChanged: (val) {
                            setState(() => _isParchmentMode = val);
                            setSheetState(() {});
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Colors.white10),
                    // Font Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Μέγεθος Γραμματοσειράς',
                          style: TextStyle(color: EverforestColors.fg, fontSize: 13.5),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded,
                                  color: EverforestColors.grey, size: 22),
                              onPressed: () {
                                if (_fontSize > 13) {
                                  setState(() => _fontSize -= 1);
                                  setSheetState(() {});
                                }
                              },
                            ),
                            Text(
                              '${_fontSize.round()} pt',
                              style: const TextStyle(
                                  color: EverforestColors.fg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  color: EverforestColors.grey, size: 22),
                              onPressed: () {
                                if (_fontSize < 30) {
                                  setState(() => _fontSize += 1);
                                  setSheetState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 16, color: Colors.white10),
                    // Auto-Scroll Speed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ταχύτητα Αυτόματης Κύλισης',
                          style: TextStyle(color: EverforestColors.fg, fontSize: 13.5),
                        ),
                        Text(
                          '${_autoScrollSpeed.toStringAsFixed(1)}x',
                          style: TextStyle(
                              color: accentGold, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    Slider(
                      value: _autoScrollSpeed,
                      min: 0.3,
                      max: 4.0,
                      divisions: 12,
                      activeColor: accentGold,
                      inactiveColor: Colors.white12,
                      onChanged: (v) {
                        setState(() => _autoScrollSpeed = v);
                        setSheetState(() {});
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        _isParchmentMode ? const Color(0xFF26201A) : EverforestColors.bg0;
    final sidebarBg =
        _isParchmentMode ? const Color(0xFF1E1A14) : const Color(0xFF232A2E);
    final textColor =
        _isParchmentMode ? const Color(0xFFEADBCE) : EverforestColors.fg;
    final rubricColor =
        _isParchmentMode ? const Color(0xFFE06C75) : EverforestColors.red;
    final accentGold =
        _isParchmentMode ? const Color(0xFFE5C07B) : EverforestColors.yellow;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                      color: EverforestColors.yellow, strokeWidth: 2),
                  const SizedBox(height: 16),
                  Text(
                    widget.serviceTitle,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : _service == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 48,
                          color: EverforestColors.grey.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text('Η υπηρεσία δεν είναι διαθέσιμη',
                          style: TextStyle(color: EverforestColors.grey, fontSize: 14)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _loadService();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Δοκιμάστε ξανά'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EverforestColors.green,
                          foregroundColor: EverforestColors.bg0,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isDesktop = width >= 1024;
                    final isTablet = width >= 600 && width < 1024;

                    return Row(
                      children: [
                        // Desktop Sidebar TOC (collapsible)
                        if (isDesktop && _desktopSidebarOpen) ...[
                          _buildSidebar(sidebarBg, textColor, accentGold),
                          Container(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ],
                        // Main content
                        Expanded(
                          child: Column(
                            children: [
                              _buildTopBar(
                                bgColor: bgColor,
                                sidebarBg: sidebarBg,
                                textColor: textColor,
                                accentGold: accentGold,
                                isDesktop: isDesktop,
                                isTablet: isTablet,
                              ),
                              Expanded(
                                child: _buildReadingArea(
                                  textColor: textColor,
                                  rubricColor: rubricColor,
                                  accentGold: accentGold,
                                  isDesktop: isDesktop,
                                  isTablet: isTablet,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildTopBar({
    required Color bgColor,
    required Color sidebarBg,
    required Color textColor,
    required Color accentGold,
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: EverforestColors.fg, size: 20),
              tooltip: 'Επιστροφή',
              onPressed: () => Navigator.pop(context),
            ),
            // Desktop Sidebar Toggle
            if (isDesktop)
              IconButton(
                icon: Icon(
                  _desktopSidebarOpen
                      ? Icons.menu_open_rounded
                      : Icons.view_sidebar_rounded,
                  color: _desktopSidebarOpen ? accentGold : EverforestColors.grey,
                  size: 20,
                ),
                tooltip: _desktopSidebarOpen
                    ? 'Απόκρυψη Περιεχομένων'
                    : 'Προβολή Περιεχομένων',
                onPressed: () =>
                    setState(() => _desktopSidebarOpen = !_desktopSidebarOpen),
              ),
            const SizedBox(width: 4),
            // Service Title & Commemoration Selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.serviceTitle,
                    style: TextStyle(
                      color: textColor,
                      fontSize: isDesktop ? 15 : 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_service?.commemorations != null &&
                      _service!.commemorations.length > 1)
                    PopupMenuButton<int>(
                      initialValue: _selectedSaintIdx,
                      tooltip: 'Επιλογή Αγίου / Εορτής',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(maxWidth: 320),
                      color: sidebarBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      onSelected: (idx) {
                        if (idx != _selectedSaintIdx) {
                          setState(() {
                            _selectedSaintIdx = idx;
                            _isLoading = true;
                          });
                          _loadService(idx);
                        }
                      },
                      itemBuilder: (context) {
                        return _service!.commemorations.map((comm) {
                          final isChosen = comm.index == _selectedSaintIdx;
                          return PopupMenuItem<int>(
                            value: comm.index,
                            height: 40,
                            child: Row(
                              children: [
                                Icon(
                                  isChosen
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  size: 16,
                                  color: isChosen
                                      ? accentGold
                                      : EverforestColors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    comm.name,
                                    style: TextStyle(
                                      color: isChosen ? accentGold : textColor,
                                      fontSize: 12.5,
                                      fontWeight: isChosen
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _service!.commemorations
                                  .firstWhere(
                                      (c) => c.index == _selectedSaintIdx,
                                      orElse: () =>
                                          _service!.commemorations.first)
                                  .name,
                              style: TextStyle(
                                color: accentGold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down_rounded,
                            color: accentGold,
                            size: 18,
                          ),
                        ],
                      ),
                    )
                  else if (_service?.subtitle.isNotEmpty ?? false)
                    Text(
                      _service!.subtitle,
                      style: TextStyle(
                        color: EverforestColors.grey.withValues(alpha: 0.8),
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Controls on Mobile / Tablet vs Desktop
            if (!isDesktop) ...[
              // TOC Sheet Button
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: Icon(Icons.toc_rounded, color: accentGold, size: 21),
                tooltip: 'Περιεχόμενα',
                onPressed: () =>
                    _openMobileToc(context, textColor, accentGold, sidebarBg),
              ),
              // Settings Sheet Button
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.tune_rounded,
                    color: EverforestColors.grey, size: 19),
                tooltip: 'Ρυθμίσεις',
                onPressed: () =>
                    _openSettingsSheet(context, textColor, accentGold, sidebarBg),
              ),
            ] else ...[
              // Desktop direct controls
              // Theme toggle
              IconButton(
                icon: Icon(
                  _isParchmentMode
                      ? Icons.dark_mode_rounded
                      : Icons.menu_book_rounded,
                  color: _isParchmentMode
                      ? accentGold
                      : EverforestColors.grey,
                  size: 19,
                ),
                tooltip: _isParchmentMode
                    ? 'Σκοτεινό Θέμα'
                    : 'Λειτουργία Περγαμηνής',
                onPressed: () =>
                    setState(() => _isParchmentMode = !_isParchmentMode),
              ),
              // Font Size
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_fontSize > 13) setState(() => _fontSize -= 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('A-',
                            style: TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Text(
                      '${_fontSize.round()}',
                      style: const TextStyle(
                          color: EverforestColors.grey, fontSize: 11),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_fontSize < 30) setState(() => _fontSize += 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text('A+',
                            style: TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Favorite star
            ValueListenableBuilder<Set<String>>(
              valueListenable: PrayerRepository.instance.favoriteIds,
              builder: (context, favs, _) {
                final isFav = favs.contains(widget.serviceId);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    color:
                        isFav ? EverforestColors.yellow : EverforestColors.grey,
                    size: 20,
                  ),
                  tooltip: isFav ? 'Αφαίρεση από Αγαπημένα' : 'Προσθήκη στα Αγαπημένα',
                  onPressed: () => PrayerRepository.instance
                      .toggleFavorite(widget.serviceId),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
      Color sidebarBg, Color textColor, Color accentGold) {
    return Container(
      width: _sidebarWidth,
      color: sidebarBg,
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(Icons.toc_rounded,
                    color: accentGold.withValues(alpha: 0.9), size: 16),
                const SizedBox(width: 6),
                Text(
                  'ΠΕΡΙΕΧΟΜΕΝΑ',
                  style: TextStyle(
                    color: accentGold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          // Section list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: _service!.sections.length,
              itemBuilder: (context, index) {
                final section = _service!.sections[index];
                if (section.header.isEmpty) return const SizedBox.shrink();
                final isActive = _activeSectionIndex == index;
                return InkWell(
                  onTap: () => _scrollToSection(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isActive
                          ? accentGold.withValues(alpha: 0.14)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          width: 3,
                          color:
                              isActive ? accentGold : Colors.transparent,
                        ),
                      ),
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color: isActive
                            ? accentGold
                            : textColor.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                      child: Text(
                        section.header,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Auto-scroll speed control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ταχύτητα κύλισης',
                        style: TextStyle(
                            color: EverforestColors.grey.withValues(alpha: 0.7),
                            fontSize: 9.5)),
                    Text('${_autoScrollSpeed.toStringAsFixed(1)}x',
                        style: TextStyle(
                            color: accentGold, fontSize: 10.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _autoScrollSpeed,
                    min: 0.3,
                    max: 4.0,
                    divisions: 12,
                    activeColor: accentGold,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setState(() => _autoScrollSpeed = v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingArea({
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
                        '\u2626',
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
                        '\u2626',
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
                      _isAutoScrolling ? '\u03a0\u03b1\u03cd\u03c3\u03b7' : '\u039a\u03cd\u03bb\u03b9\u03c3\u03b7',
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
      padding: isDynamic
          ? (isMobile ? const EdgeInsets.fromLTRB(14, 12, 12, 14) : const EdgeInsets.fromLTRB(18, 16, 16, 18))
          : EdgeInsets.symmetric(
              vertical: isMobile ? 8 : 12,
              horizontal: isMobile ? 4 : 8,
            ),
      decoration: isDynamic
          ? BoxDecoration(
              color: accentGold.withValues(alpha: _isParchmentMode ? 0.08 : 0.05),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
              border: Border(
                left: BorderSide(color: accentGold.withValues(alpha: 0.7), width: 3.5),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          if (section.header.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    section.header,
                    style: TextStyle(
                      color: rubricColor,
                      fontSize: isMobile
                          ? (_fontSize * 0.88).clamp(13.5, 17.5)
                          : _fontSize * 0.92,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                if (isDynamic) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
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
            const SizedBox(height: 10),
            Divider(
              height: 1,
              color: isDynamic
                  ? accentGold.withValues(alpha: 0.25)
                  : (_isParchmentMode
                      ? Colors.black.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.06)),
            ),
            const SizedBox(height: 10),
          ],

          // Content
          _buildPrayerText(section.content, textColor, isRubric, rubricColor, isMobile),
        ],
      ),
    );
  }

  Widget _buildPrayerText(
      String content, Color textColor, bool isRubric, Color rubricColor, bool isMobile) {
    final paragraphs = content.split('\n\n');

    return RichText(
      text: TextSpan(
        children: paragraphs.map((para) {
          final trimmed = para.trim();
          if (trimmed.isEmpty) {
            return TextSpan(text: '\n', style: TextStyle(fontSize: _fontSize * 0.5));
          }

          final lines = trimmed.split('\n');
          final isSubHeader = lines.length == 1 &&
              trimmed.length < 75 &&
              !trimmed.endsWith('.') &&
              !trimmed.endsWith('\u00b7') &&
              !trimmed.endsWith(')');

          if (isSubHeader && !isRubric) {
            return TextSpan(
              children: [
                const TextSpan(text: '\n'),
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
                const TextSpan(text: '\n\n'),
              ],
            );
          }

          // Parse lines within paragraph to highlight speakers and verse numbers
          final lineSpans = <InlineSpan>[];
          for (int li = 0; li < lines.length; li++) {
            final line = lines[li];
            final tline = line.trim();

            if (li > 0) {
              lineSpans.add(const TextSpan(text: '\n'));
            }

            final speakerMatch = RegExp(r'^(\u0399\u0395\u03a1\u0395\u03a5\u03a3|\u0394\u0399\u0391\u039a\u039f\u039d\u039f\u03a3|\u03a7\u039f\u03a1\u039f\u03a3|\u0391\u039d\u0391\u0393\u039d\u03a9\u03a3\u03a4\u0397\u03a3|\u039b\u0391\u039f\u03a3)(\s*\([^)]+\))?:').firstMatch(tline);
            final verseMatch = RegExp(r"^(\u03a3\u03c4\u03af\u03c7\.\s*[^:\n]+:|\u03a3\u03c4\u03af\u03c7\u03bf\u03b9[^:\n]*:|\u0394\u03cc\u03be\u03b1\s*\u03a0\u03b1\u03c4\u03c1\u03af\.\.\.|\u039a\u03b1\u1f76\s*\u03bd\u1fe6\u03bd\.\.\.|\u0394\u03cc\u03be\u03b1\.\.\.|\u03a3\u03a4\u0399\u03a7\u039f\u039b\u039f\u0393\u0399\u0391\s*[^:\n]+:|\u0397\s*\u03a5\u03a0\u0391\u039a\u039f\u0397:|\u039f\u0399\s*\u0391\u039d\u0391\u0392\u0391\u0398\u039c\u039f\u0399|\u03a4\u039f\s*\u03a0\u03a1\u039f\u039a\u0395\u0399\u039c\u0395\u039d\u039f\u039d|\u0391\u03a0\u039f\u039b\u03a5\u03a4\u0399\u039a\u0399[\u0391\u039f]\u039d[^:\n]*:|\u039a\u039f\u039d\u03a4\u0391\u039a\u0399\u039f\u039d[^:\n]*:|\u039f\s*\u039f\u0399\u039a\u039f\u03a3:|\u0395\u039e\u0391\u03a0\u039f\u03a3\u03a4\u0395\u0399\u039b\u0391\u03a1\u0399\u039f\u039d[^:\n]*:|\u0398\u0395\u039f\u03a4\u039f\u039a\u0399\u039f\u039d:|\u1f49\s*\u0395\u1f31\u03c1\u03bc\u03cc\u03c2:|\u1f49\s*\u0395\u03b9\u03c1\u03bc\u03cc\u03c2:|\u039a\u0391\u0398\u0399\u03a3\u039c\u0391\s*[^:\n]+:|\u1f68\u03b4\u1f74\s*[^:\n]+:)").firstMatch(tline);

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

          lineSpans.add(const TextSpan(text: '\n\n'));
          return TextSpan(children: lineSpans);
        }).toList(),
      ),
    );
  }

  String _getDynamicTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'apolytikion':
        return 'ΑΠΟΛΥΤΙΚΙΟΝ';
      case 'kontakion':
        return 'ΚΟΝΤΑΚΙΟΝ';
      case 'antiphon':
        return 'ΑΝΤΙΦΩΝΟΝ';
      case 'eisodikon':
        return 'ΕΙΣΟΔΙΚΟΝ';
      case 'katavasies':
        return 'ΚΑΤΑΒΑΣΙΑΙ';
      case 'epistle':
        return 'ΑΠΟΣΤΟΛΟΣ';
      case 'gospel':
      case 'eothinon_gospel':
        return 'ΕΥΑΓΓΕΛΙΟΝ';
      case 'megalynarion':
        return 'ΜΕΓΑΛΥΝΑΡΙΟΝ';
      case 'koinonikon':
        return 'ΚΟΙΝΩΝΙΚΟΝ';
      case 'ainoi':
        return 'ΑΙΝΟΙ';
      case 'kekragaria':
        return 'ΚΕΚΡΑΓΑΡΙΑ';
      case 'aposticha':
        return 'ΑΠΟΣΤΙΧΑ';
      case 'kathismata':
        return 'ΚΑΘΙΣΜΑΤΑ';
      case 'anavathmoi':
        return 'ΑΝΑΒΑΘΜΟΙ';
      case 'exaposteilarion':
        return 'ΕΞΑΠΟΣΤΕΙΛΑΡΙΟΝ';
      case 'doxastikon':
        return 'ΔΟΞΑΣΤΙΚΟΝ';
      case 'prokeimenon':
        return 'ΠΡΟΚΕΙΜΕΝΟΝ';
      case 'canon':
        return 'ΚΑΝΩΝ';
      case 'apolysis':
        return 'ΑΠΟΛΥΣΙΣ';
      default:
        return 'ΤΥΠΙΚΟΝ';
    }
  }
}
