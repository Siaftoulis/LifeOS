import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'dark_radar_widget.dart';
import 'geofence_editor_widget.dart';

class MapsDashboardWidget extends StatelessWidget {
  const MapsDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          const Expanded(
            flex: 3,
            child: DarkRadarWidget(),
          ),
          const SizedBox(height: 24),
          const Text('Geofences', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Expanded(
            flex: 2,
            child: GeofenceEditorWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.radar, color: EverforestColors.cyan, size: 28),
        const SizedBox(width: 12),
        const Text('Maps & Live Tracking', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: EverforestColors.cyan.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
          child: const Row(
            children: [
              Icon(Icons.wifi_tethering, color: EverforestColors.cyan, size: 16),
              SizedBox(width: 8),
              Text('LIVE', style: TextStyle(color: EverforestColors.cyan, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
