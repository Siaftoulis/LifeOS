import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import '../common/user_avatar_with_frame.dart';

class OnlineUserEntry {
  final String username;
  final String displayName;
  final String role;
  final String avatarAsset;
  final String frame;
  final String nameStyle;
  final String status;
  final String device;
  final int lastActive;
  final bool isOnline;

  OnlineUserEntry({
    required this.username,
    required this.displayName,
    required this.role,
    required this.avatarAsset,
    required this.frame,
    required this.nameStyle,
    required this.status,
    required this.device,
    required this.lastActive,
    required this.isOnline,
  });

  factory OnlineUserEntry.fromJson(Map<String, dynamic> json) {
    return OnlineUserEntry(
      username: json['username'] ?? '',
      displayName: json['display_name'] ?? '',
      role: json['role'] ?? 'USER',
      avatarAsset: json['avatar_asset'] ?? '',
      frame: json['frame'] ?? 'none',
      nameStyle: json['name_style'] ?? 'default',
      status: json['status'] ?? '',
      device: json['device'] ?? 'Offline',
      lastActive: json['last_active'] ?? 0,
      isOnline: json['is_online'] ?? false,
    );
  }
}

class OnlineUsersListWidget extends StatefulWidget {
  const OnlineUsersListWidget({super.key});

  @override
  State<OnlineUsersListWidget> createState() => _OnlineUsersListWidgetState();
}

class _OnlineUsersListWidgetState extends State<OnlineUsersListWidget> {
  List<OnlineUserEntry> _users = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchOnlineUsers();
    // Auto-refresh presence every 8 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) _fetchOnlineUsers(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOnlineUsers({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/auth/online');
      if (res is List && mounted) {
        setState(() {
          _users = res
              .whereType<Map>()
              .map((m) => OnlineUserEntry.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          // Sort: online users first
          _users.sort((a, b) {
            if (a.isOnline && !b.isOnline) return -1;
            if (!a.isOnline && b.isOnline) return 1;
            return b.lastActive.compareTo(a.lastActive);
          });
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatLastActive(int timestamp) {
    if (timestamp <= 0) return 'Ποτέ';
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));
    if (diff.inMinutes < 1) return 'Μόλις τώρα';
    if (diff.inMinutes < 60) return '${diff.inMinutes}λ πριν';
    if (diff.inHours < 24) return '${diff.inHours}ω πριν';
    return '${diff.inDays}ημ πριν';
  }

  IconData _deviceIcon(String device) {
    final d = device.toLowerCase();
    if (d.contains('windows') || d.contains('pc')) return Icons.computer;
    if (d.contains('android') || d.contains('mobile') || d.contains('phone') || d.contains('ios')) return Icons.smartphone;
    if (d.contains('web')) return Icons.language;
    if (d.contains('linux')) return Icons.terminal;
    return Icons.devices;
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = _users.where((u) => u.isOnline).length;

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.hub_outlined, color: EverforestColors.aqua),
              const SizedBox(width: 10),
              const Text(
                'Ενεργοί Χρήστες & Συσκευές',
                style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: onlineCount > 0 ? EverforestColors.green.withValues(alpha: 0.2) : EverforestColors.bg2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: onlineCount > 0 ? EverforestColors.green : EverforestColors.grey),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: onlineCount > 0 ? EverforestColors.green : EverforestColors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$onlineCount Online',
                      style: TextStyle(
                        color: onlineCount > 0 ? EverforestColors.green : EverforestColors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, color: EverforestColors.grey, size: 20),
                tooltip: 'Ανανέωση',
                onPressed: () => _fetchOnlineUsers(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: EverforestColors.aqua),
              ),
            )
          else if (_users.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Δεν βρέθηκαν χρήστες', style: TextStyle(color: EverforestColors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final user = _users[index];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: user.isOnline 
                          ? EverforestColors.green.withValues(alpha: 0.3)
                          : EverforestColors.bg2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar with Frame & Online badge
                      UserAvatarWithFrame(
                        avatarAsset: user.avatarAsset,
                        username: user.username,
                        frameId: user.frame,
                        radius: 20,
                        isOnline: user.isOnline,
                      ),
                      const SizedBox(width: 14),

                      // User details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.displayName.isNotEmpty ? user.displayName : user.username,
                                  style: UserNameStyles.apply(
                                    user.nameStyle,
                                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: user.role == 'ADMIN' 
                                        ? EverforestColors.red.withValues(alpha: 0.2)
                                        : EverforestColors.blue.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: TextStyle(
                                      color: user.role == 'ADMIN' ? EverforestColors.red : EverforestColors.blue,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}',
                              style: const TextStyle(color: EverforestColors.grey, fontSize: 12),
                            ),
                            if (user.status.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                user.status,
                                style: TextStyle(color: EverforestColors.fg.withValues(alpha: 0.7), fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Device & Online status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (user.isOnline) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_deviceIcon(user.device), size: 14, color: EverforestColors.green),
                                const SizedBox(width: 4),
                                Text(
                                  user.device,
                                  style: const TextStyle(color: EverforestColors.green, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Ενεργός τώρα',
                              style: TextStyle(color: EverforestColors.green, fontSize: 10),
                            ),
                          ] else ...[
                            Text(
                              _formatLastActive(user.lastActive),
                              style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Αποσυνδεδεμένος',
                              style: TextStyle(color: EverforestColors.grey, fontSize: 10),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
