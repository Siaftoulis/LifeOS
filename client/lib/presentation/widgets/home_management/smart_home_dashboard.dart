import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../api_client.dart';

class SmartHomeDashboard extends StatefulWidget {
  const SmartHomeDashboard({super.key});

  @override
  State<SmartHomeDashboard> createState() => _SmartHomeDashboardState();
}

class _SmartHomeDashboardState extends State<SmartHomeDashboard> {
  @override
  void initState() {
    super.initState();
    _syncDevicesFromBackend();
  }

  Future<void> _syncDevicesFromBackend() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/home/devices');
      if (res is List) {
        final dao = AppDatabase.instance.homeManagementDao;
        for (var item in res) {
          final device = item as Map<String, dynamic>;
          final id = device['device_id'] as String;
          final existing = await dao.getDeviceById(id);
          
          final entry = SmartDevicesCompanion(
            id: drift.Value(id),
            name: drift.Value(device['name'] as String? ?? id),
            type: drift.Value(device['type'] as String? ?? 'light'),
            state: drift.Value(device['state'] as String? ?? 'OFF'),
            isDirty: const drift.Value(0),
          );

          if (existing == null) {
            await dao.insertDevice(entry);
          } else {
            await dao.updateDevice(entry);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync smart home devices: $e');
    }
  }

  Future<void> _toggleDevice(SmartDevice device) async {
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/home/devices/toggle', {
        'device_id': device.id,
      });
      
      if (res is Map<String, dynamic> && res['status'] == 'success') {
        final newState = res['state'] as String;
        final dao = AppDatabase.instance.homeManagementDao;
        await dao.updateDevice(SmartDevicesCompanion(
          id: drift.Value(device.id),
          name: drift.Value(device.name),
          type: drift.Value(device.type),
          state: drift.Value(newState),
          isDirty: const drift.Value(0),
        ));
      }
    } catch (e) {
      debugPrint('Failed to toggle smart device: $e');
    }
  }

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
            child: StreamBuilder<List<SmartDevice>>(
              stream: AppDatabase.instance.homeManagementDao.watchAllDevices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
                }
                final devices = snapshot.data!;
                if (devices.isEmpty) {
                  return const Center(child: Text('No Smart Devices configured.', style: TextStyle(color: EverforestColors.grey)));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    return _buildDeviceCard(devices[index]);
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(SmartDevice device) {
    final isOn = device.state == 'ON';
    
    IconData icon;
    switch(device.type) {
      case 'light': icon = isOn ? Icons.lightbulb : Icons.lightbulb_outline; break;
      case 'climate': icon = Icons.thermostat; break;
      case 'appliance': icon = Icons.kitchen; break;
      case 'switch': icon = Icons.power; break;
      case 'lock': icon = isOn ? Icons.lock_open : Icons.lock; break;
      default: icon = Icons.device_hub; break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOn ? EverforestColors.bg2 : EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOn ? EverforestColors.green.withValues(alpha: 0.5) : EverforestColors.bg2),
        boxShadow: isOn
            ? [BoxShadow(color: EverforestColors.green.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)]
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
                icon,
                color: isOn ? EverforestColors.green : EverforestColors.grey,
                size: 32,
              ),
              Switch(
                value: isOn,
                onChanged: (val) => _toggleDevice(device),
                activeThumbColor: EverforestColors.green,
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
                device.state,
                style: TextStyle(
                  color: isOn ? EverforestColors.green : EverforestColors.grey,
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
