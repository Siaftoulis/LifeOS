import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class SmartHomeDashboard extends StatelessWidget {
  const SmartHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Smart Home',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: EverforestColors.bg1,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: EverforestColors.bg2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.thermostat, color: EverforestColors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text('72°F', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 16, color: EverforestColors.bg2),
                    const SizedBox(width: 16),
                    const Icon(Icons.water_drop, color: EverforestColors.blue, size: 20),
                    const SizedBox(width: 8),
                    const Text('45%', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: mockDevices.length,
              itemBuilder: (context, index) {
                return _buildDeviceCard(mockDevices[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(MockDevice device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: device.isOn ? EverforestColors.bg2 : EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: device.isOn ? EverforestColors.green.withOpacity(0.5) : EverforestColors.bg2),
        boxShadow: device.isOn
            ? [BoxShadow(color: EverforestColors.green.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                device.icon,
                color: device.isOn ? EverforestColors.green : EverforestColors.grey,
                size: 32,
              ),
              Switch(
                value: device.isOn,
                onChanged: (val) {},
                activeColor: EverforestColors.green,
                inactiveThumbColor: EverforestColors.grey,
                inactiveTrackColor: EverforestColors.bg0,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                device.statusText,
                style: TextStyle(
                  color: device.isOn ? EverforestColors.green : EverforestColors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MockDevice {
  final String name;
  final IconData icon;
  final bool isOn;
  final String statusText;

  MockDevice(this.name, this.icon, this.isOn, this.statusText);
}

final mockDevices = [
  MockDevice('Living Room Lights', Icons.lightbulb, true, '80% Brightness'),
  MockDevice('Kitchen Lights', Icons.lightbulb_outline, false, 'Off'),
  MockDevice('Front Door Lock', Icons.lock, true, 'Locked'),
  MockDevice('AC Unit', Icons.ac_unit, true, 'Cooling to 70°F'),
  MockDevice('Security Camera', Icons.videocam, true, 'Recording'),
  MockDevice('Smart Speaker', Icons.speaker, false, 'Idle'),
];
