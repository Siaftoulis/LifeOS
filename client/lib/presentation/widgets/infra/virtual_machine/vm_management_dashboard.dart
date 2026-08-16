import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../theme/everforest_colors.dart';
import '../../../../database/database.dart';
import '../../../../api_client.dart';
import '../../../../core/telemetry/telemetry_reporter.dart';

class VMManagementDashboard extends StatefulWidget {
  const VMManagementDashboard({super.key});

  @override
  State<VMManagementDashboard> createState() => _VMManagementDashboardState();
}

class _VMManagementDashboardState extends State<VMManagementDashboard> {
  @override
  void initState() {
    super.initState();
    _syncVMsFromBackend();
  }

  Future<void> _syncVMsFromBackend() async {
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/vm');
      if (res is List) {
        final dao = AppDatabase.instance.vmDao;
        for (var item in res) {
          final vm = item as Map<String, dynamic>;
          
          final entry = VirtualMachinesCompanion(
            id: drift.Value(vm['id'] as String),
            name: drift.Value(vm['name'] as String),
            type: drift.Value(vm['type'] as String),
            state: drift.Value(vm['state'] as String),
            ramLimit: drift.Value((vm['ram'] ?? 512) as int),
            updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
            isDirty: const drift.Value(0),
          );

          try {
            await dao.insertVM(entry);
          } catch (_) {
            await dao.updateVM(entry);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to sync VMs: $e');
    }
  }

  Future<void> _toggleVM(VirtualMachine vm) async {
    try {
      final action = vm.state == 'RUNNING' || vm.state == 'Running' ? 'stop' : 'start';
      final res = await ApiClient.instance.postDaemon('/api/v1/vm/toggle', {
        'vm_id': vm.id,
        'action': action,
      });
      if (res is Map<String, dynamic> && res['status'] == 'action_dispatched') {
        final dao = AppDatabase.instance.vmDao;
        TelemetryReporter.instance.track('vm', 'toggled', {'vm_id': vm.id, 'action': action});
        await dao.updateVM(VirtualMachinesCompanion(
          id: drift.Value(vm.id),
          name: drift.Value(vm.name),
          type: drift.Value(vm.type),
          state: drift.Value(res['state'] as String),
          ramLimit: drift.Value(vm.ramLimit),
          updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
          isDirty: const drift.Value(0),
        ));
      }
    } catch (e) {
      debugPrint('Failed to toggle VM: $e');
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 16,
            children: [
              const Text(
                'Virtual Machines',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, color: EverforestColors.bg0),
                label: const Text(
                  'New VM',
                  style: TextStyle(color: EverforestColors.bg0, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EverforestColors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<List<VirtualMachine>>(
              stream: AppDatabase.instance.vmDao.watchAllVMs(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: EverforestColors.purple));
                }
                final vms = snapshot.data!;
                if (vms.isEmpty) {
                  return const Center(child: Text('No Virtual Machines found.', style: TextStyle(color: EverforestColors.grey)));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: vms.length,
                  itemBuilder: (context, index) {
                    return _buildVMCard(vms[index]);
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVMCard(VirtualMachine vm) {
    final isRunning = vm.state == 'RUNNING' || vm.state == 'Running';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        vm.type == 'Linux' ? Icons.terminal : Icons.window,
                        color: EverforestColors.fg,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vm.name,
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              vm.type,
                              style: const TextStyle(
                                color: EverforestColors.grey,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRunning ? EverforestColors.green.withValues(alpha: 0.2) : EverforestColors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vm.state,
                    style: TextStyle(
                      color: isRunning ? EverforestColors.green : EverforestColors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isRunning) ...[
              _buildResourceBar('CPU', 0.0, EverforestColors.yellow),
              const SizedBox(height: 8),
              _buildResourceBar('RAM', 0.0, EverforestColors.aqua),
            ] else
              const Center(
                child: Text('Machine is powered off', style: TextStyle(color: EverforestColors.grey)),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _toggleVM(vm),
                  icon: Icon(
                    isRunning ? Icons.stop_circle_outlined : Icons.play_circle_fill,
                    color: isRunning ? EverforestColors.red : EverforestColors.green,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings, color: EverforestColors.grey),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildResourceBar(String label, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 36,
          child: Text(label, style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: EverforestColors.bg2,
              color: color,
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text('${(percentage * 100).toInt()}%', style: const TextStyle(color: EverforestColors.fg, fontSize: 12)),
        ),
      ],
    );
  }
}
