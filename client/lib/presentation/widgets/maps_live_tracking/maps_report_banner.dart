import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class MapsReportBanner extends StatelessWidget {
  final Map<String, dynamic>? lastReport;

  const MapsReportBanner({super.key, required this.lastReport});

  @override
  Widget build(BuildContext context) {
    if (lastReport == null) return const SizedBox.shrink();
    
    final triggered = lastReport!['triggered_geofences'] as List? ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: triggered.isNotEmpty ? EverforestColors.green.withOpacity(0.15) : EverforestColors.bg1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: triggered.isNotEmpty ? EverforestColors.green : EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Icon(
            triggered.isNotEmpty ? Icons.notifications_active : Icons.check_circle_outline,
            color: triggered.isNotEmpty ? EverforestColors.green : EverforestColors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              triggered.isNotEmpty
                ? 'In ${triggered.length} geofence(s)'
                : 'Position reported - outside all geofences',
              style: TextStyle(
                color: triggered.isNotEmpty ? EverforestColors.green : EverforestColors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
