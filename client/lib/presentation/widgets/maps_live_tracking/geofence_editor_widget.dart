import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class GeofenceEditorWidget extends StatelessWidget {
  const GeofenceEditorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _GeofenceRow(name: 'Home Base', lat: '37.9838', lon: '23.7275', radius: '150m', active: true),
        _GeofenceRow(name: 'Work Office', lat: '38.0123', lon: '23.7345', radius: '200m', active: true),
        _GeofenceRow(name: 'Gym', lat: '37.9642', lon: '23.7121', radius: '100m', active: false),
      ],
    );
  }
}

class _GeofenceRow extends StatelessWidget {
  final String name, lat, lon, radius;
  final bool active;

  const _GeofenceRow({required this.name, required this.lat, required this.lon, required this.radius, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: active ? EverforestColors.green : EverforestColors.grey, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('Lat: $lat | Lon: $lon | R: $radius', style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: active,
            onChanged: (val) {},
            activeColor: EverforestColors.green,
            activeTrackColor: EverforestColors.green.withOpacity(0.3),
            inactiveThumbColor: EverforestColors.grey,
            inactiveTrackColor: EverforestColors.bg2,
          ),
        ],
      ),
    );
  }
}
