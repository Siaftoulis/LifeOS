import 'package:flutter/material.dart';
import '../../../core/update/ota_update_service.dart';
import '../../../theme/everforest_colors.dart';

class SystemUpdatesWidget extends StatefulWidget {
  const SystemUpdatesWidget({super.key});

  @override
  State<SystemUpdatesWidget> createState() => _SystemUpdatesWidgetState();
}

class _SystemUpdatesWidgetState extends State<SystemUpdatesWidget> {
  final OtaUpdateService _ota = OtaUpdateService.instance;
  List<LifeOSRelease> _history = [];
  bool _isLoadingHistory = false;
  String? _rollingBackTag;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final list = await _ota.fetchReleaseHistory();
    if (mounted) {
      setState(() {
        _history = list;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _handleRollback(LifeOSRelease release) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: EverforestColors.bg2),
        ),
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: EverforestColors.yellow),
            const SizedBox(width: 10),
            Text('Rollback to ${release.tagName}', style: const TextStyle(color: EverforestColors.fg)),
          ],
        ),
        content: Text(
          'Are you sure you want to rollback LifeOS to version ${release.tagName}? Your local database and offline music/media will remain safe.',
          style: const TextStyle(color: EverforestColors.fg, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.yellow,
              foregroundColor: EverforestColors.bg0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ROLLBACK NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _rollingBackTag = release.tagName);
      final ok = await _ota.triggerRollback(release);
      if (mounted) {
        setState(() => _rollingBackTag = null);
        if (!ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: EverforestColors.red,
              content: Text('Failed to download rollback build. Check network connection.'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: EverforestColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update_rounded, color: EverforestColors.green, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System & OTA Updates',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Silent background updates with 1-tap version rollback',
                      style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _ota.isChecking,
                builder: (context, checking, _) {
                  return OutlinedButton.icon(
                    onPressed: checking
                        ? null
                        : () async {
                            await _ota.checkSilentUpdate();
                            await _loadHistory();
                          },
                    icon: checking
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.green),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16, color: EverforestColors.green),
                    label: Text(
                      checking ? 'Checking...' : 'Check Now',
                      style: const TextStyle(color: EverforestColors.green, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: EverforestColors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Current Version Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EverforestColors.bg0,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EverforestColors.bg2),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INSTALLED VERSION', style: TextStyle(color: EverforestColors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _ota.currentVersionTag,
                          style: const TextStyle(color: EverforestColors.fg, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Build #${_ota.currentBuildNumber}',
                            style: const TextStyle(color: EverforestColors.grey, fontSize: 11, fontFamily: 'JetBrainsMono'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _ota.isDownloading,
                  builder: (context, downloading, _) {
                    if (downloading) {
                      return ValueListenableBuilder<double>(
                        valueListenable: _ota.downloadProgress,
                        builder: (context, progress, _) {
                          return Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(value: progress > 0 ? progress : null, strokeWidth: 2.5, color: EverforestColors.green),
                              ),
                              const SizedBox(width: 8),
                              Text('${(progress * 100).toInt()}%', style: const TextStyle(color: EverforestColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          );
                        },
                      );
                    }
                    return ValueListenableBuilder<LifeOSRelease?>(
                      valueListenable: _ota.updateReadyRelease,
                      builder: (context, readyRelease, _) {
                        if (readyRelease != null) {
                          return ElevatedButton.icon(
                            onPressed: () => _ota.installUpdate(),
                            icon: const Icon(Icons.download_done_rounded, size: 16),
                            label: Text('INSTALL ${readyRelease.tagName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EverforestColors.green,
                              foregroundColor: EverforestColors.bg0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          );
                        }
                        return const Row(
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: EverforestColors.green, size: 18),
                            SizedBox(width: 6),
                            Text('Up to date', style: TextStyle(color: EverforestColors.green, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // History & Rollback Section
          const Row(
            children: [
              Icon(Icons.history_toggle_off_rounded, color: EverforestColors.yellow, size: 18),
              SizedBox(width: 8),
              Text(
                'Version History & Rollback',
                style: TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator(color: EverforestColors.green))
                : _history.isEmpty
                    ? const Center(child: Text('No historical releases found', style: TextStyle(color: EverforestColors.grey, fontSize: 12)))
                    : ListView.separated(
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final rel = _history[idx];
                          final isCurrent = rel.tagName == _ota.currentVersionTag;
                          final isRollingBack = _rollingBackTag == rel.tagName;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: EverforestColors.bg0,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isCurrent ? EverforestColors.green.withValues(alpha: 0.5) : EverforestColors.bg2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          rel.tagName,
                                          style: TextStyle(
                                            color: isCurrent ? EverforestColors.green : EverforestColors.fg,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: EverforestColors.green.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text('ACTIVE', style: TextStyle(color: EverforestColors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${rel.publishedAt.year}-${rel.publishedAt.month.toString().padLeft(2, '0')}-${rel.publishedAt.day.toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (!isCurrent)
                                  ElevatedButton.icon(
                                    onPressed: isRollingBack ? null : () => _handleRollback(rel),
                                    icon: isRollingBack
                                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.bg0))
                                        : const Icon(Icons.undo_rounded, size: 14),
                                    label: Text(
                                      isRollingBack ? 'Downloading...' : 'Rollback',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: EverforestColors.bg2,
                                      foregroundColor: EverforestColors.fg,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                              ],
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
