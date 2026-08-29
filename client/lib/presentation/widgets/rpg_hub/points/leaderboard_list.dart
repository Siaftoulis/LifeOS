import 'package:flutter/material.dart';
import '../../../../api_client.dart';
import '../../../../theme/everforest_colors.dart';

class LeaderboardList extends StatefulWidget {
  const LeaderboardList({super.key});

  @override
  State<LeaderboardList> createState() => _LeaderboardListState();
}

class _LeaderboardListState extends State<LeaderboardList> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final res =
          await ApiClient.instance.getDaemon('/api/v1/points/leaderboard');
      if (mounted) {
        setState(() {
          _users = res as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: EverforestColors.blue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
              color: EverforestColors.blue.withValues(alpha: 0.05),
              blurRadius: 20)
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('RANKING',
              style: TextStyle(
                  color: EverforestColors.blue,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2)),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: EverforestColors.blue))
                : _users.isEmpty
                    ? const Center(
                        child: Text('No users found',
                            style: TextStyle(color: EverforestColors.grey)))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          final isFirst = index == 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isFirst
                                  ? EverforestColors.blue.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: isFirst
                                      ? EverforestColors.blue
                                          .withValues(alpha: 0.3)
                                      : EverforestColors.bg2),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '#${user['rank'] ?? (index + 1)}',
                                  style: TextStyle(
                                    color: isFirst
                                        ? EverforestColors.blue
                                        : EverforestColors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isFirst ? 20 : 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    user['username'] ?? 'Unknown',
                                    style: TextStyle(
                                      color: EverforestColors.fg,
                                      fontWeight: isFirst
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: EverforestColors.yellow,
                                        size: isFirst ? 18 : 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${user['points'] ?? 0}',
                                      style: TextStyle(
                                        color: EverforestColors.fg,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isFirst ? 16 : 14,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
