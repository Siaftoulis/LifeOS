import 'package:flutter/material.dart';
import '../../../../auth_service.dart';
import '../../../../theme/everforest_colors.dart';

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

  String get _initials {
    final user = AuthService.instance.currentUser.value;
    final name = (user != null && user.displayName.isNotEmpty)
        ? user.displayName
        : (user?.username ?? "Player One");
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser.value;
    final name = user != null && user.displayName.isNotEmpty
        ? user.displayName
        : (user?.username ?? "Player One");
    final isAdmin = user?.role == 'ADMIN';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    EverforestColors.green.withValues(alpha: 0.9),
                    EverforestColors.blue.withValues(alpha: 0.9),
                  ],
                ),
                border: Border.all(color: EverforestColors.green, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: EverforestColors.green.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: EverforestColors.bg0,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: EverforestColors.yellow.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: EverforestColors.yellow, width: 1),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: EverforestColors.yellow,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ],
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
