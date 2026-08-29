import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import '../../../database/home_screen_dao.dart';

class OnlineUsersListWidget extends StatefulWidget {
  const OnlineUsersListWidget({super.key});

  @override
  State<OnlineUsersListWidget> createState() => _OnlineUsersListWidgetState();
}

class _OnlineUsersListWidgetState extends State<OnlineUsersListWidget> {
  late final HomeScreenDao _dao;

  @override
  void initState() {
    super.initState();
    _dao = HomeScreenDao(AppDatabase.instance);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SystemUser>>(
      stream: _dao.watchAllUsers(),
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];
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
              if (users.isEmpty)
                const Center(
                  child: Text('No users found', style: TextStyle(color: EverforestColors.grey)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: EverforestColors.bg2,
                        child: Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?', style: const TextStyle(color: EverforestColors.green)),
                      ),
                      title: Text(user.username, style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
                      subtitle: Text('ID: ${user.id}', style: const TextStyle(color: EverforestColors.grey)),
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
      },
    );
  }
}
