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
  LifeOSRelease? _latestRelease;

  @override
  void initState() {
    super.initState();
    _checkLatest();
  }

  Future<void> _checkLatest({bool force = false}) async {
    await _ota.checkSilentUpdate(forceRefresh: force);
    final rel = await _ota.fetchLatestRelease(forceRefresh: force);
    if (mounted) {
      setState(() => _latestRelease = rel);
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
                      'Seamless 1-tap in-place updates via Server Cache & GitHub',
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
                        : () => _checkLatest(force: true),
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
          // Latest Release Details Section
          const Row(
            children: [
              Icon(Icons.new_releases_outlined, color: EverforestColors.aqua, size: 18),
              SizedBox(width: 8),
              Text(
                'Latest Available Release',
                style: TextStyle(color: EverforestColors.fg, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _latestRelease == null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    child: const Center(
                      child: Text(
                        'Checking for latest release details...',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg0,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _latestRelease!.title,
                              style: const TextStyle(
                                color: EverforestColors.fg,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: EverforestColors.aqua.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _latestRelease!.tagName,
                                style: const TextStyle(color: EverforestColors.aqua, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Published: ${_latestRelease!.publishedAt.year}-${_latestRelease!.publishedAt.month.toString().padLeft(2, '0')}-${_latestRelease!.publishedAt.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: EverforestColors.bg2, height: 1),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _latestRelease!.body.isNotEmpty ? _latestRelease!.body : 'No detailed changelog provided for this release.',
                              style: const TextStyle(color: EverforestColors.fg, fontSize: 12, height: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
