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

  @override
  void initState() {
    super.initState();
    _loadServices();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: EverforestColors.fg),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.bookTitle,
          style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.w600),
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
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return _buildServiceCard(service);
      },
    );
  }

  Widget _buildServiceCard(dynamic service) {
    final serviceId = service['id'] ?? '';
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
        padding: const EdgeInsets.all(16),
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
                color: EverforestColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories_rounded, color: EverforestColors.yellow, size: 20),
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
                  Text(
                    '${service['sections_count'] ?? (service['sections'] as List?)?.length ?? 0} τμήματα',
                    style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
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
