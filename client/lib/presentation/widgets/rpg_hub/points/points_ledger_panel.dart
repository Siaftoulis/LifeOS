import 'package:flutter/material.dart';
import '../../../../api_client.dart';
import '../../../../auth_service.dart';
import '../../../../theme/everforest_colors.dart';

/// Ledger history + last-7-days XP bars. Data: GET /api/v1/points/ledger.
class PointsLedgerPanel extends StatefulWidget {
  const PointsLedgerPanel({super.key});

  @override
  State<PointsLedgerPanel> createState() => _PointsLedgerPanelState();
}

class _PointsLedgerPanelState extends State<PointsLedgerPanel> {
  List<dynamic> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res =
          await ApiClient.instance.getDaemon('/api/v1/points/ledger');
      if (mounted) {
        setState(() {
          _entries = res is List ? res : [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _mine {
    final user = AuthService.instance.currentUser.value;
    if (user == null) return _entries;
    return _entries
        .where((e) => (e as Map)['user_id'] == user.username)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('POINTS LEDGER',
              style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: EverforestColors.green),
              ),
            )
          else if (_mine.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No transactions yet',
                  style: TextStyle(color: EverforestColors.grey)),
            )
          else ...[
            _WeeklyXpChart(entries: _mine),
            const SizedBox(height: 16),
            Text('LAST ACTIVITY',
                style: TextStyle(
                    color: EverforestColors.grey.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _mine.length > 25 ? 25 : _mine.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: EverforestColors.bg2),
                itemBuilder: (context, i) => _LedgerRow(entry: _mine[i] as Map),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final Map entry;

  @override
  Widget build(BuildContext context) {
    final points = entry['points'] is num ? (entry['points'] as num).toInt() : 0;
    final gained = points > 0;
    final ts = entry['timestamp'] is num ? (entry['timestamp'] as num).toInt() : 0;
    final d = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            gained ? Icons.add_circle : Icons.remove_circle,
            color: gained ? EverforestColors.green : EverforestColors.red,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry['event'] as String? ?? 'Transaction',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
            ),
          ),
          Text(
            '${d.day}/${d.month}',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              '${gained ? '+' : ''}$points',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: gained ? EverforestColors.green : EverforestColors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// XP earned per day for the last 7 days, plain bars (no chart library).
class _WeeklyXpChart extends StatelessWidget {
  const _WeeklyXpChart({required this.entries});

  final List<dynamic> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final startMs = start.millisecondsSinceEpoch;
      final endMs = start.add(const Duration(days: 1)).millisecondsSinceEpoch;
      var total = 0;
      for (final e in entries) {
        final p = (e as Map)['points'];
        final t = e['timestamp'];
        if (p is num &&
            p > 0 &&
            t is num &&
            t * 1000 >= startMs &&
            t * 1000 < endMs) {
          total += p.toInt();
        }
      }
      return (label: '${start.day}/${start.month}', xp: total);
    });
    final maxXp = days.fold(0, (m, d) => d.xp > m ? d.xp : m);
    const chartHeight = 110.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: days.map((d) {
            final h = maxXp == 0 ? 2.0 : 8.0 + (d.xp / maxXp) * (chartHeight - 8);
            return Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 18,
                        height: h,
                        decoration: BoxDecoration(
                          color: EverforestColors.green.withValues(alpha: 0.7),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d.label,
                      style: const TextStyle(
                          color: EverforestColors.grey, fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          maxXp == 0 ? 'No XP earned this week' : 'Weekly XP — max $maxXp',
          style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
        ),
      ],
    );
  }
}