import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class MapsLiveFeedPreview extends StatelessWidget {
  final List<Map<String, dynamic>> liveLocations;

  const MapsLiveFeedPreview({super.key, required this.liveLocations});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: liveLocations.isEmpty
        ? const Center(child: Text('No live updates', style: TextStyle(color: EverforestColors.grey, fontSize: 12)))
        : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: liveLocations.length,
            itemBuilder: (ctx, i) {
              final loc = liveLocations[i];
              return Container(
                width: 120,
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: EverforestColors.bg2.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${loc['device_id'] ?? '?'}', style: const TextStyle(color: EverforestColors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('${(loc['latitude'] as num?)?.toStringAsFixed(3) ?? '?'}', style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                    Text('${(loc['longitude'] as num?)?.toStringAsFixed(3) ?? '?'}', style: const TextStyle(color: EverforestColors.grey, fontSize: 10)),
                  ],
                ),
              );
            },
          ),
    );
  }
}
