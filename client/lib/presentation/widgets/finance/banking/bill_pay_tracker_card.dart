import 'package:flutter/material.dart';

class BillPayTrackerCard extends StatelessWidget {
  final int totalBillsCents;
  final int roundedTransferCents;
  final int rolloverSurplusCents;

  const BillPayTrackerCard({
    Key? key,
    required this.totalBillsCents,
    required this.roundedTransferCents,
    required this.rolloverSurplusCents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF343f44), // bg1
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3d484d), width: 1), // bg2
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BILLS ROUND-UP ENGINE', style: TextStyle(color: Color(0xFF859289), fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatBlock('Total Pending', totalBillsCents, const Color(0xFFe67e80)), // Red
              _buildStatBlock('Rounded Transfer', roundedTransferCents, const Color(0xFFa7c080)), // Green
              _buildStatBlock('Rollover Surplus', rolloverSurplusCents, const Color(0xFFdbbc7f)), // Yellow
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock(String label, int cents, Color color) {
    final euros = cents / 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '€${euros.toStringAsFixed(2)}',
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'JetBrainsMono'),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF859289), fontSize: 10)),
      ],
    );
  }
}
