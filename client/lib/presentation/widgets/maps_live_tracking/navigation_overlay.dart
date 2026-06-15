import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class NavigationOverlay extends StatelessWidget {
  final VoidCallback onClose;
  
  const NavigationOverlay({super.key, required this.onClose});

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
          children: [
            Row(
              children: [
                const Icon(Icons.directions, color: EverforestColors.blue),
                const SizedBox(width: 12),
                const Text('Navigation', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: EverforestColors.grey),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInput('Choose starting point', Icons.my_location),
            const SizedBox(height: 12),
            _buildInput('Choose destination', Icons.location_on, isDest: true),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.blue,
                foregroundColor: EverforestColors.bg0,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String hint, IconData icon, {bool isDest = false}) {
    return TextField(
      style: const TextStyle(color: EverforestColors.fg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: EverforestColors.grey),
        prefixIcon: Icon(icon, color: isDest ? EverforestColors.red : EverforestColors.green),
        filled: true,
        fillColor: EverforestColors.bg1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
