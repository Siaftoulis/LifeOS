import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class SensorLogsPanel extends StatelessWidget {
  const SensorLogsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, color: EverforestColors.blue, size: 20),
              const SizedBox(width: 8),
              const Text('Environment (Raspberry Pi)', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
              const Spacer(),
              const Text('Live', style: TextStyle(color: EverforestColors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SensorValue(label: 'Living Room', temp: '22.5°C', humidity: '45%'),
              _SensorValue(label: 'Bedroom', temp: '21.0°C', humidity: '50%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorValue extends StatelessWidget {
  final String label, temp, humidity;
  const _SensorValue({required this.label, required this.temp, required this.humidity});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(temp, style: const TextStyle(color: EverforestColors.yellow, fontSize: 20, fontWeight: FontWeight.bold)),
        Text('💧 $humidity', style: const TextStyle(color: EverforestColors.blue, fontSize: 12)),
      ],
    );
  }
}
