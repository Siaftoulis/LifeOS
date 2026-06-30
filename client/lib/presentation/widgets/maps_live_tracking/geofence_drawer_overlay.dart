import 'package:flutter/material.dart';
import '../../../database/database.dart';
import '../../../theme/everforest_colors.dart';

class GeofenceDrawerOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final bool isDrawingMode;
  final VoidCallback onToggleDrawMode;
  final List<Geofence> geofences;
  final Function(String, bool) onToggleActive;
  final Function(String) onDelete;
  
  const GeofenceDrawerOverlay({
    super.key,
    required this.onClose,
    required this.isDrawingMode,
    required this.onToggleDrawMode,
    required this.geofences,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 280,
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
                  icon: Icon(isDrawingMode ? Icons.check : Icons.add_location_alt, color: isDrawingMode ? EverforestColors.green : EverforestColors.fg),
                  label: Text(
                    isDrawingMode ? 'Drawing Tap Map' : 'Add Geofence', 
                    style: TextStyle(color: isDrawingMode ? EverforestColors.green : EverforestColors.fg, fontWeight: FontWeight.bold)
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: EverforestColors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
            const Divider(color: EverforestColors.bg2),
            Expanded(
              child: geofences.isEmpty
                  ? const Center(
                      child: Text(
                        'Tap "Add Geofence" and tap anywhere on the map to define a geofence zone.',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: geofences.length,
                      itemBuilder: (context, index) {
                        final g = geofences[index];
                        return ListTile(
                          leading: const Icon(Icons.crop_square, color: EverforestColors.green),
                          title: Text(g.name, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600)),
                          subtitle: Text('Radius: ${g.radius.round()}m', style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: g.isActive == 1,
                                onChanged: (val) => onToggleActive(g.id, val),
                                activeColor: EverforestColors.green,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: EverforestColors.red, size: 20),
                                onPressed: () => onDelete(g.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
