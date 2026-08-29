import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../theme/everforest_colors.dart';

/// Poweramp-style Audiophile Track Metadata Inspector modal.
class TrackMetadataModal extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final String trackId;
  final String url;
  final Duration duration;
  final MusicTrack? track;

  const TrackMetadataModal({
    super.key,
    required this.title,
    required this.artist,
    this.album = '',
    required this.trackId,
    required this.url,
    required this.duration,
    this.track,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String artist,
    String album = '',
    required String trackId,
    required String url,
    required Duration duration,
    MusicTrack? track,
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
        track: track,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _getHighResCoverUrl(String url) {
    if (url.isEmpty) return '';
    if (kIsWeb && Uri.base.scheme == 'https' && url.startsWith('http://')) {
      url = url.replaceFirst('http://', 'https://');
    }
    // Attempt highest quality YouTube thumbnail if applicable
    if (url.contains('ytimg.com') || url.contains('ggpht.com')) {
      return url.replaceAll('hqdefault.jpg', 'maxresdefault.jpg');
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = url.startsWith('file:') || !url.contains('ytstream');
    final t = track ??
        MusicRepository.instance.tracks.value.firstWhere(
          (item) => item.id == trackId,
          orElse: () => MusicTrack(
            id: trackId,
            title: title,
            artist: artist,
            album: album,
            thumbnail: '',
            duration: duration.inSeconds.toDouble(),
          ),
        );

    final codec = t.codec.isNotEmpty
        ? t.codec.toUpperCase()
        : (url.endsWith('.mp3')
            ? 'MPEG Audio Layer 3 (MP3)'
            : 'Advanced Audio Coding (AAC-LC)');

    final container = url.endsWith('.mp3') ? 'Audio / MP3' : 'MPEG-4 Audio (M4A)';
    final bitrate = t.bitrate != null && t.bitrate! > 0
        ? '${t.bitrate} kbps'
        : (url.endsWith('.mp3') ? '320 kbps (CBR)' : '256 kbps (VBR)');

    final sampleRate = t.sampleRate != null && t.sampleRate! > 0
        ? '${t.sampleRate} Hz (${t.bitDepth ?? 16}-bit PCM)'
        : '44,100 Hz (16-bit PCM)';

    final channels = t.channels != null && t.channels! > 0
        ? 'Stereo ${t.channels}.0 (Left/Right)'
        : 'Stereo 2.0 (Left/Right)';

    final coverUrl = _getHighResCoverUrl(t.thumbnail);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: EverforestColors.bg0,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 35,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SingleChildScrollView(
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

            // Top Header: Artwork preview + Title & Hi-Res Badge
            Row(
              children: [
                if (coverUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showFullCover(context, coverUrl),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: EverforestColors.green.withValues(alpha: 0.25),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: EverforestColors.bg1,
                            child: const Icon(Icons.music_note_rounded,
                                color: EverforestColors.green),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: EverforestColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: EverforestColors.green.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: EverforestColors.green, size: 26),
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
                      const SizedBox(height: 2),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: EverforestColors.aqua.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: EverforestColors.aqua.withValues(alpha: 0.4)),
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

            // Metadata Table
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EverforestColors.bg1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                      'Artist', artist.isNotEmpty ? artist : 'Unknown Artist'),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow(
                      'Album', album.isNotEmpty ? album : 'Single / EP'),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Container', container),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Audio Codec', codec),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Bitrate', bitrate),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Sample Rate', sampleRate),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Channels', channels),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Duration', _formatDuration(duration)),
                  if (t.replayGainTrack != null) ...[
                    const Divider(color: Colors.white10, height: 18),
                    _buildInfoRow('ReplayGain Track',
                        '${t.replayGainTrack! >= 0 ? '+' : ''}${t.replayGainTrack!.toStringAsFixed(2)} dB'),
                  ],
                  if (t.playCount > 0) ...[
                    const Divider(color: Colors.white10, height: 18),
                    _buildInfoRow('Play Count', '${t.playCount} times'),
                  ],
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Storage Source',
                      isLocal ? 'Local Storage Vault' : 'YouTube Music (Direct Stream)'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stream URL Clipboard Copy Action
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stream URL copied to clipboard'),
                    duration: Duration(seconds: 2),
                    backgroundColor: EverforestColors.bg1,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        color: EverforestColors.grey, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: EverforestColors.grey,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                      ),
                    ),
                    const Icon(Icons.copy_rounded,
                        color: EverforestColors.grey, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullCover(BuildContext context, String coverUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                coverUrl,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              label: const Text('Close', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
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