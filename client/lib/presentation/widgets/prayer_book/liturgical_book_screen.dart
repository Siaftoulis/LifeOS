import 'package:flutter/material.dart';
import '../../../api_client.dart';
import '../../../theme/everforest_colors.dart';
import 'prayer_reader_screen.dart';

class LiturgicalBookScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const LiturgicalBookScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  State<LiturgicalBookScreen> createState() => _LiturgicalBookScreenState();
}

class _LiturgicalBookScreenState extends State<LiturgicalBookScreen> {
  List<dynamic> _services = [];
  List<dynamic> _tones = [];
  bool _loading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, String> _categoryLabels = {
    'all': 'Όλα',
    'occasional': 'Περιστασιακές',
    'saints': 'Αγίων',
    'akolouthies': 'Ακολουθίες',
    'paraklisis': 'Παρακλήσεις',
    'xairetismoi': 'Χαιρετισμοί',
    'daily': 'Καθημερινές',
    'healing': 'Υγείας',
  };

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final data = await ApiClient.instance.getDaemon('/api/v1/prayers/${widget.bookId}');
      if (data is Map) {
        setState(() {
          if (widget.bookId == 'octoechos' && data['tones'] != null) {
            _tones = data['tones'] as List;
            _services = [];
            for (final tone in _tones) {
              final svcs = tone['services'] ?? [];
              for (final svc in svcs) {
                _services.add({...svc, '_tone': tone['tone_name'] ?? ''});
              }
            }
          } else {
            _services = data['services'] ?? data['feasts'] ?? data['prayers'] ?? [];
          }
          _loading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<String> _getAvailableCategories() {
    final cats = <String>{'all'};
    for (final s in _services) {
      final c = s['category']?.toString();
      if (c != null && c.isNotEmpty) {
        cats.add(c);
      }
    }
    return cats.toList();
  }

  List<dynamic> get _filteredServices {
    return _services.where((s) {
      if (_selectedCategory != 'all') {
        final cat = s['category']?.toString().toLowerCase() ?? '';
        if (cat != _selectedCategory) return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final title = s['title']?.toString().toLowerCase() ?? '';
        if (!title.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookTitle,
              style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (!_loading && _services.isNotEmpty)
              Text(
                '${_filteredServices.length} κείμενα',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: EverforestColors.yellow))
          : _tones.isNotEmpty
              ? _buildToneList()
              : _buildServiceList(),
    );
  }

  Widget _buildToneList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tones.length,
      itemBuilder: (context, index) {
        final tone = _tones[index];
        final toneName = tone['tone_name'] ?? '';
        final toneNameGr = tone['tone_name_greek'] ?? '';
        final services = tone['services'] ?? [];
        final sectionCount = (services as List).fold<int>(0, (sum, s) => sum + ((s['sections'] as List?)?.length ?? 0));
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: EverforestColors.bg1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: EverforestColors.bg2),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              title: Text(
                '$toneNameGr - $toneName',
                style: const TextStyle(color: EverforestColors.fg, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${services.length} services, $sectionCount sections',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
              ),
              iconColor: EverforestColors.yellow,
              children: services.map<Widget>((svc) {
                return _buildServiceCard(svc);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceList() {
    final availableCats = _getAvailableCategories();
    final items = _filteredServices;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: EverforestColors.fg, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Αναζήτηση προσευχής ή ακολουθίας...',
              hintStyle: const TextStyle(color: EverforestColors.grey, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: EverforestColors.grey, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: EverforestColors.grey, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: EverforestColors.bg1,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Category chips if more than 1 category exists
        if (availableCats.length > 2)
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: availableCats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final catKey = availableCats[idx];
                final isSelected = _selectedCategory == catKey;
                final label = _categoryLabels[catKey] ?? catKey;
                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = catKey);
                    }
                  },
                  labelStyle: TextStyle(
                    color: isSelected ? EverforestColors.bg0 : EverforestColors.fg,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  selectedColor: EverforestColors.yellow,
                  backgroundColor: EverforestColors.bg1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? EverforestColors.yellow : EverforestColors.bg2,
                    ),
                  ),
                  showCheckmark: false,
                );
              },
            ),
          ),

        const SizedBox(height: 8),

        // Services list
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'Δεν βρέθηκαν κείμενα',
                    style: TextStyle(color: EverforestColors.grey.withValues(alpha: 0.8), fontSize: 14),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final service = items[index];
                    return _buildServiceCard(service);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final serviceId = service['id'] ?? '';
    final rawCat = service['category']?.toString() ?? '';
    final catLabel = _categoryLabels[rawCat] ?? rawCat;

    IconData icon = Icons.auto_stories_rounded;
    Color iconColor = EverforestColors.yellow;
    if (rawCat == 'paraklisis') {
      icon = Icons.volunteer_activism_rounded;
      iconColor = EverforestColors.blue;
    } else if (rawCat == 'xairetismoi') {
      icon = Icons.star_rounded;
      iconColor = EverforestColors.aqua;
    } else if (rawCat == 'akolouthies') {
      icon = Icons.church_rounded;
      iconColor = EverforestColors.purple;
    } else if (rawCat == 'saints') {
      icon = Icons.person_rounded;
      iconColor = EverforestColors.orange;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrayerReaderScreen(
              serviceId: serviceId,
              serviceTitle: service['title'] ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: EverforestColors.bg1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EverforestColors.bg2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['title'] ?? '',
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (catLabel.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            catLabel,
                            style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${service['sections_count'] ?? (service['sections'] as List?)?.length ?? 0} τμήματα',
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: EverforestColors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
