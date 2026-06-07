import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class InfraHub extends StatelessWidget {
  const InfraHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Half: Terminal Outputs
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: EverforestColors.grey.withOpacity(0.5), width: 1.5),
              ),
              padding: const EdgeInsets.all(24),
              child: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('user@lifeos-daemon:~\$ tail -f /var/log/sync.log', style: TextStyle(color: EverforestColors.blue, fontFamily: 'JetBrainsMono', fontSize: 12)),
                    SizedBox(height: 16),
                    Text('[INFO] tsnet mesh tunnel established.', style: TextStyle(color: EverforestColors.fg, fontFamily: 'JetBrainsMono', fontSize: 11)),
                    SizedBox(height: 8),
                    Text('[INFO] Authenticated peer: remote-relay.', style: TextStyle(color: EverforestColors.fg, fontFamily: 'JetBrainsMono', fontSize: 11)),
                    SizedBox(height: 8),
                    Text('[WARN] High latency detected (124ms).', style: TextStyle(color: EverforestColors.yellow, fontFamily: 'JetBrainsMono', fontSize: 11)),
                    SizedBox(height: 8),
                    Text('[ERROR] Connection drop on wlan0.', style: TextStyle(color: EverforestColors.red, fontFamily: 'JetBrainsMono', fontSize: 11)),
                    SizedBox(height: 8),
                    Text('[INFO] Reconnected successfully.', style: TextStyle(color: EverforestColors.fg, fontFamily: 'JetBrainsMono', fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Bottom Half: File Transfer Queue
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: EverforestColors.grey.withOpacity(0.5), width: 1.5),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE TRANSFERS', style: TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 24),
                    _buildTransferItem('ubuntu-24.04-live-server-amd64.iso', 0.65, '1.2 GB / 2.6 GB', EverforestColors.fg),
                    const SizedBox(height: 24),
                    _buildTransferItem('vault-backup-20260607.tar.gz', 1.0, 'Completed', EverforestColors.fg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem(String filename, double progress, String status, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(filename, style: const TextStyle(color: EverforestColors.fg, fontSize: 11, fontFamily: 'JetBrainsMono')),
            Text(status, style: TextStyle(color: color, fontSize: 10, fontFamily: 'JetBrainsMono')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EverforestColors.grey.withOpacity(0.3), width: 1),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      color: EverforestColors.fg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
