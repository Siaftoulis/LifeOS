import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class GeofenceDrawerOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDrawingMode;
  final VoidCallback onToggleDrawMode;
  
  const GeofenceDrawerOverlay({
    super.key,
    required this.onClose,
    required this.isDrawingMode,
    required this.onToggleDrawMode,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: EverforestColors.bg0.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(top: BorderSide(color: EverforestColors.bg2, width: 2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -4))
          ]
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.share_location, color: EverforestColors.green),
                const SizedBox(width: 12),
                const Text('Geofences', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: onToggleDrawMode,
                  icon: Icon(isDrawingMode ? Icons.check : Icons.draw, color: isDrawingMode ? EverforestColors.blue : EverforestColors.fg),
                  label: Text(isDrawingMode ? 'Finish Draw' : 'Draw New', style: TextStyle(color: isDrawingMode ? EverforestColors.blue : EverforestColors.fg)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: EverforestColors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
            const Divider(color: EverforestColors.bg2),
            Expanded(
              child: ListView(
                children: [
                  _buildZoneRow('Home Base', active: true),
                  _buildZoneRow('Office', active: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneRow(String name, {required bool active}) {
    return ListTile(
      leading: const Icon(Icons.crop_square, color: EverforestColors.green),
      title: Text(name, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600)),
      subtitle: const Text('Automation: Enabled', style: TextStyle(color: EverforestColors.grey, fontSize: 12)),
      trailing: Switch(
        value: active,
        onChanged: (val) {},
        activeColor: EverforestColors.green,
      ),
    );
  }
}
