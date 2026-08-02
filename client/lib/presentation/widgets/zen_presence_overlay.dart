import 'package:flutter/material.dart';
import '../../core/obsidian/zen_collab_service.dart';
import '../../database/custom_sync_manager.dart';

class ZenPresenceOverlay extends StatelessWidget {
  final Map<String, RemotePresence> presences;
  final SyncStatus? syncStatus;

  const ZenPresenceOverlay({
    super.key,
    required this.presences,
    this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    final activeUsers = presences.values.where(
      (p) => DateTime.now().difference(p.lastSeen).inSeconds < 30,
    ).toList();

    final showSyncBadge = syncStatus != null && syncStatus != SyncStatus.idle;

    if (activeUsers.isEmpty && !showSyncBadge) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSyncBadge) ...[
            _buildSyncStatusBadge(context, syncStatus!),
            if (activeUsers.isNotEmpty) const SizedBox(width: 8),
          ],
          ...activeUsers.map((presence) {
            final color = _parseColor(presence.colorHex);
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Tooltip(
                message: '${presence.userName} editing',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        presence.userName,
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(BuildContext context, SyncStatus status) {
    final (color, label, icon) = _getSyncStatusDecoration(status);

    return Tooltip(
      message: 'Sync status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String, IconData) _getSyncStatusDecoration(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return (Colors.blueAccent, 'Syncing...', Icons.sync);
      case SyncStatus.synced:
        return (Colors.green, 'Synced', Icons.check_circle_outline);
      case SyncStatus.retrying:
        return (Colors.orangeAccent, 'Retrying...', Icons.sync_problem);
      case SyncStatus.error:
        return (Colors.redAccent, 'Sync Error', Icons.error_outline);
      case SyncStatus.idle:
        return (Colors.grey, 'Idle', Icons.cloud_queue);
    }
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF7E57C2);
    }
  }
}
