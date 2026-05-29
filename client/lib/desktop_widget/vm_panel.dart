import 'package:flutter/material.dart';

class VmPanel extends StatelessWidget {
  final Map<String, dynamic> data;
  const VmPanel({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vms = data['vms'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Virtual Machines', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        if (vms.isEmpty)
          const Text('No VMs Active', style: TextStyle(color: Colors.white70)),
        for (var vm in vms)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Typically Hyper-V state 2 is Running. Adjust if different.
                    color: (vm['State'] == 2) ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  vm['Name']?.toString() ?? 'Unknown VM', 
                  style: const TextStyle(color: Colors.white)
                ),
              ],
            ),
          )
      ],
    );
  }
}
