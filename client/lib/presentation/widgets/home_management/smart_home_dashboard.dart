import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../core/general_engine/engine_repository.dart';
import '../../../core/general_engine/general_engine_client.dart';

class SmartHomeDashboard extends StatefulWidget {
  const SmartHomeDashboard({super.key});

  @override
  State<SmartHomeDashboard> createState() => _SmartHomeDashboardState();
}

class _SmartHomeDashboardState extends State<SmartHomeDashboard> {
  Future<void> _toggleDevice(GeneralEngineEntity device) async {
    final currentState = device.payload['state'] as String? ?? 'OFF';
    final newState = currentState == 'ON' ? 'OFF' : 'ON';
    
    final updatedPayload = Map<String, dynamic>.from(device.payload);
    updatedPayload['state'] = newState;

    final updatedEntity = GeneralEngineEntity(
      id: device.id,
      type: device.type,
      creatorId: device.creatorId,
      payload: updatedPayload,
      sharedWith: device.sharedWith,
      assignedTo: device.assignedTo,
      createdAt: device.createdAt,
      updatedAt: DateTime.now(),
    );

    await EngineRepository.instance.saveEntity(updatedEntity);
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
            child: ValueListenableBuilder<List<GeneralEngineEntity>>(
              valueListenable: EngineRepository.instance.allEntities,
              builder: (context, entities, child) {
                final devices = EngineRepository.instance.smartDevices;
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
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(GeneralEngineEntity device) {
    final stateStr = device.payload['state'] as String? ?? 'OFF';
    final isOn = stateStr == 'ON';
    final type = device.payload['type'] as String? ?? 'light';
    final name = device.payload['name'] as String? ?? device.id;
    
    IconData icon;
    switch(type) {
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
                name,
                style: const TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stateStr,
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
