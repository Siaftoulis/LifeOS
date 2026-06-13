import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class QuarantineWarningsPanel extends StatelessWidget {
  const QuarantineWarningsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {'file': 'keygen_crack.exe', 'threat': 'Trojan.Win32.Generic', 'status': 'INFECTED'},
      {'file': 'tutorial_pdf.zip', 'threat': 'None', 'status': 'CLEAN'},
      {'file': 'movie_rip.mp4', 'threat': 'Scanning...', 'status': 'PENDING'},
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
          const Text('ClamAV Security Sandbox', style: TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final status = alert['status'] as String;
                
                IconData icon;
                Color color;
                if (status == 'CLEAN') {
                  icon = Icons.check_circle; color = EverforestColors.green;
                } else if (status == 'INFECTED') {
                  icon = Icons.warning; color = EverforestColors.red;
                } else {
                  icon = Icons.sync; color = EverforestColors.yellow;
                }

                return Card(
                  color: EverforestColors.bg0,
                  child: ListTile(
                    leading: Icon(icon, color: color),
                    title: Text(alert['file'] as String, style: const TextStyle(color: EverforestColors.fg)),
                    subtitle: Text(alert['threat'] as String, style: TextStyle(color: status == 'INFECTED' ? EverforestColors.red : EverforestColors.grey)),
                    trailing: status == 'CLEAN' 
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.green, foregroundColor: EverforestColors.bg0),
                            onPressed: () {},
                            child: const Text('Promote'),
                          )
                        : (status == 'INFECTED' ? const Icon(Icons.delete_forever, color: EverforestColors.red) : null),
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
