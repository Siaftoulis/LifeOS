import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class QuarantineView extends StatelessWidget {
  const QuarantineView({super.key});

  @override
  Widget build(BuildContext context) {
    final files = [
      {'name': 'taxes_2026.pdf', 'size': '2.4 MB', 'status': 'CLEAN'},
      {'name': 'unknown_script.sh', 'size': '12 KB', 'status': 'INFECTED'},
      {'name': 'vacation.zip', 'size': '45 MB', 'status': 'PENDING'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ClamAV Upload Sandbox', style: TextStyle(color: EverforestColors.fg, fontSize: 16)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final status = file['status'] as String;
                
                IconData icon;
                Color color;
                if (status == 'CLEAN') {
                  icon = Icons.verified; color = EverforestColors.green;
                } else if (status == 'INFECTED') {
                  icon = Icons.warning; color = EverforestColors.red;
                } else {
                  icon = Icons.hourglass_empty; color = EverforestColors.yellow;
                }

                return ListTile(
                  leading: Icon(icon, color: color),
                  title: Text(file['name'] as String, style: const TextStyle(color: EverforestColors.fg)),
                  subtitle: Text(file['size'] as String, style: const TextStyle(color: EverforestColors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color),
                    ),
                    child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
