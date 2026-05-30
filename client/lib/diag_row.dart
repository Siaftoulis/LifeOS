import 'package:flutter/material.dart';
import 'theme.dart';

enum DiagStatus { healthy, connecting, blocked }

class DiagRow extends StatelessWidget {
  final String label;
  final String detail;
  final DiagStatus status;
  const DiagRow({super.key, required this.label, required this.detail, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 0.5),
      ),
      child: Row(children: [
        _icon,
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: OLEDTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: OLEDTheme.textSecondary, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget get _icon => switch (status) {
    DiagStatus.healthy => const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
    DiagStatus.connecting => const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 2.5)),
    DiagStatus.blocked => const Icon(Icons.cancel, color: Colors.redAccent, size: 28),
  };

  Color get _borderColor => switch (status) {
    DiagStatus.healthy => Colors.greenAccent.withOpacity(0.15),
    DiagStatus.connecting => Colors.orange.withOpacity(0.15),
    DiagStatus.blocked => Colors.redAccent.withOpacity(0.15),
  };
}
