import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'device_grid_toggle.dart';
import 'sensor_logs_panel.dart';

class SmartHomeDashboard extends StatelessWidget {
  const SmartHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Home Management', style: TextStyle(color: EverforestColors.fg, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const SensorLogsPanel(),
          const SizedBox(height: 24),
          const Text('Smart Devices', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: const [
                DeviceGridToggle(name: 'Living Room Light', type: 'LIGHT', isOn: true),
                DeviceGridToggle(name: 'Kitchen LED', type: 'LIGHT', isOn: false),
                DeviceGridToggle(name: 'AC Thermostat', type: 'THERMOSTAT', isOn: true),
                DeviceGridToggle(name: 'Front Door Lock', type: 'SWITCH', isOn: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
