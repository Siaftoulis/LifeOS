import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../theme/everforest_colors.dart';

/// Poweramp-style Audiophile Track Metadata Inspector modal.
class TrackMetadataModal extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final String trackId;
  final String url;
  final Duration duration;

  const TrackMetadataModal({
    super.key,
    required this.title,
    required this.artist,
    this.album = '',
    required this.trackId,
    required this.url,
    required this.duration,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String artist,
    String album = '',
    required String trackId,
    required String url,
    required Duration duration,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => TrackMetadataModal(
        title: title,
        artist: artist,
        album: album,
        trackId: trackId,
        url: url,
        duration: duration,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = url.startsWith('file:') || !url.contains('ytstream');
    final codec = url.endsWith('.mp3') ? 'MPEG Audio Layer 3 (MP3)' : 'Advanced Audio Coding (AAC-LC)';
    final container = url.endsWith('.mp3') ? 'Audio / MP3' : 'MPEG-4 Audio (M4A)';
    final sampleRate = '44,100 Hz';
    final bitrate = url.endsWith('.mp3') ? '320 kbps (CBR)' : '256 kbps (VBR)';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 30,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: EverforestColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EverforestColors.green.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.info_outline_rounded, color: EverforestColors.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AUDIO SPECIFICATIONS',
                      style: TextStyle(
                        color: EverforestColors.green,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: EverforestColors.aqua.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: EverforestColors.aqua.withValues(alpha: 0.4)),
                ),
                child: const Text(
                  'HI-RES',
                  style: TextStyle(
                    color: EverforestColors.aqua,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EverforestColors.bg0,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildInfoRow('Artist', artist.isNotEmpty ? artist : 'Unknown Artist'),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Container', container),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Audio Codec', codec),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Bitrate', bitrate),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Sample Rate', sampleRate),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Channels', 'Stereo 2.0 (Left/Right)'),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Duration', _formatDuration(duration)),
                const Divider(color: Colors.white10, height: 20),
                _buildInfoRow('Source', isLocal ? 'Local Storage / Vault' : 'YouTube Music (Direct Stream)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stream URL copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded, color: EverforestColors.grey, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                  const Icon(Icons.copy_rounded, color: EverforestColors.grey, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: EverforestColors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: EverforestColors.fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
