import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class VMManagementDashboard extends StatelessWidget {
  const VMManagementDashboard({super.key});

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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: mockVms.length,
              itemBuilder: (context, index) {
                return _buildVMCard(mockVms[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVMCard(MockVM vm) {
    final isRunning = vm.status == 'Running';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    vm.os == 'Linux' ? Icons.terminal : Icons.window,
                    color: EverforestColors.fg,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vm.name,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vm.os,
                        style: const TextStyle(
                          color: EverforestColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isRunning ? EverforestColors.green.withOpacity(0.2) : EverforestColors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  vm.status,
                  style: TextStyle(
                    color: isRunning ? EverforestColors.green : EverforestColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isRunning) ...[
            _buildResourceBar('CPU', vm.cpuUsage, EverforestColors.yellow),
            const SizedBox(height: 8),
            _buildResourceBar('RAM', vm.ramUsage, EverforestColors.aqua),
          ] else
            const Center(
              child: Text('Machine is powered off', style: TextStyle(color: EverforestColors.grey)),
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () {},
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

class MockVM {
  final String name;
  final String os;
  final String status;
  final double cpuUsage;
  final double ramUsage;

  MockVM(this.name, this.os, this.status, this.cpuUsage, this.ramUsage);
}

final mockVms = [
  MockVM('Dev Server', 'Linux', 'Running', 0.45, 0.72),
  MockVM('Windows Test', 'Windows 11', 'Stopped', 0.0, 0.0),
  MockVM('Docker Host', 'Linux', 'Running', 0.85, 0.60),
  MockVM('Legacy DB', 'Linux', 'Running', 0.12, 0.40),
];
