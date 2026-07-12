import 'package:flutter/material.dart';
import '../../../../auth_service.dart';

class PlayerCardHeader extends StatelessWidget {
  final int effectiveLevel;
  final int age;
  final VoidCallback onRefresh;

  const PlayerCardHeader({
    super.key,
    required this.effectiveLevel,
    required this.age,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser.value;
    final name = user != null && user.displayName.isNotEmpty
        ? user.displayName
        : (user?.username ?? "Player One");

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, size: 40, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Lvl $effectiveLevel  |  Age $age",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70),
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
