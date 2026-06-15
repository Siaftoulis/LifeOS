import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../theme/everforest_colors.dart';

class MapsDashboardHeader extends StatelessWidget {
  final WebSocketChannel? wsChannel;

  const MapsDashboardHeader({super.key, required this.wsChannel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.map, color: EverforestColors.cyan, size: 28),
        const SizedBox(width: 12),
        const Text('Maps & Live Tracking', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (wsChannel != null ? EverforestColors.green : EverforestColors.red).withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                wsChannel != null ? Icons.wifi_tethering : Icons.wifi_off,
                color: wsChannel != null ? EverforestColors.green : EverforestColors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                wsChannel != null ? 'LIVE' : 'OFFLINE',
                style: TextStyle(
                  color: wsChannel != null ? EverforestColors.green : EverforestColors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
