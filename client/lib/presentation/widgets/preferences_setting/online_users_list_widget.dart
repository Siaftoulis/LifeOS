import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class OnlineUsersListWidget extends StatelessWidget {
  const OnlineUsersListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for online users as requested ("Προς το παρόν μπορείς να δείξεις και μέσα εμένα...")
    final List<Map<String, String>> onlineUsers = [
      {
        'username': 'panospds',
        'name': 'Panos PDS',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.people_outline, color: EverforestColors.blue),
              SizedBox(width: 8),
              Text('Online Users', style: TextStyle(color: EverforestColors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: onlineUsers.length,
            itemBuilder: (context, index) {
              final user = onlineUsers[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: EverforestColors.bg2,
                  child: Text(user['name']![0].toUpperCase(), style: const TextStyle(color: EverforestColors.green)),
                ),
                title: Text(user['username']!, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
                subtitle: Text(user['name']!, style: const TextStyle(color: EverforestColors.grey)),
                trailing: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: EverforestColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
