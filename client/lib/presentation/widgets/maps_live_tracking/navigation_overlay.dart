import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/everforest_colors.dart';

class NavigationOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final Function(LatLng) onRouteSelected;
  
  const NavigationOverlay({
    super.key, 
    required this.onClose,
    required this.onRouteSelected,
  });

  static const LatLng homeLocation = LatLng(38.000, 23.733); // Stavropoulou 41, Athens
  static const LatLng workLocation = LatLng(38.0402, 23.7880); // The Mall Athens

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: EverforestColors.bg0.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: EverforestColors.bg2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.directions, color: EverforestColors.blue),
                const SizedBox(width: 12),
                const Text('Quick Navigation', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: EverforestColors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                onRouteSelected(homeLocation);
                onClose();
              },
              icon: const Icon(Icons.home),
              label: const Text('Route to Home (Stavropoulou 41)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.green,
                foregroundColor: EverforestColors.bg0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                onRouteSelected(workLocation);
                onClose();
              },
              icon: const Icon(Icons.work),
              label: const Text('Route to Work (The Mall Athens)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.blue,
                foregroundColor: EverforestColors.bg0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
