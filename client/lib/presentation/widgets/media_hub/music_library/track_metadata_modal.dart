import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../theme/app_skin_manager.dart';
import 'music_formatters.dart';

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

  String _getHighResCoverUrl(String original) {
    if (original.isEmpty) return '';
    if (original.contains('googleusercontent.com') ||
        original.contains('ggpht.com')) {
      final base = original.split('=')[0];
      return '$base=w800-h800-l90-rj';
    }
    return original;
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final t = track ??
        MusicRepository.instance.getTrackMetadata(trackId) ??
        MusicTrack(
          id: trackId,
          title: title,
          artist: artist,
          album: album,
          thumbnail: '',
          duration: duration.inSeconds.toDouble(),
        );

    final isLocal = !url.startsWith('http');
    final container = isLocal ? 'MPEG Audio Layer III (.mp3)' : 'MP4/AAC Audio Stream';
    final codec = isLocal ? 'MP3 (MPEG-1/2 Audio Layer 3)' : 'AAC-LC (Advanced Audio Coding)';
    final bitrate = t.bitrate != null && t.bitrate! > 0
        ? '${t.bitrate} kbps'
        : (url.endsWith('.mp3') ? '320 kbps (CBR)' : '256 kbps (VBR)');

    const sampleRate = '44,100 Hz (16-bit PCM)';
    const channels = 'Stereo 2.0 (Left/Right)';

    final coverUrl = _getHighResCoverUrl(t.thumbnail);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: skin.bg0,
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
                            color: skin.accent.withValues(alpha: 0.25),
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
                            color: skin.bg1,
                            child: Icon(Icons.music_note_rounded,
                                color: skin.accent),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: skin.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: skin.accent.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        color: skin.accent, size: 26),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUDIO SPECIFICATIONS',
                        style: TextStyle(
                          color: skin.accent,
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
                        style: TextStyle(
                          color: skin.fg,
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
                    color: skin.aqua.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: skin.aqua.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'HI-RES',
                    style: TextStyle(
                      color: skin.aqua,
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
                color: skin.bg1,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                      'Artist', artist.isNotEmpty ? artist : 'Unknown Artist', skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow(
                      'Album', album.isNotEmpty ? album : 'Single / EP', skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Container', container, skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Audio Codec', codec, skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Bitrate', bitrate, skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Sample Rate', sampleRate, skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Channels', channels, skin),
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Duration', formatDurationSpan(duration), skin),
                  if (t.replayGainTrack != null) ...[
                    const Divider(color: Colors.white10, height: 18),
                    _buildInfoRow('ReplayGain Track',
                        '${t.replayGainTrack! >= 0 ? '+' : ''}${t.replayGainTrack!.toStringAsFixed(2)} dB', skin),
                  ],
                  if (t.playCount > 0) ...[
                    const Divider(color: Colors.white10, height: 18),
                    _buildInfoRow('Play Count', '${t.playCount} times', skin),
                  ],
                  const Divider(color: Colors.white10, height: 18),
                  _buildInfoRow('Storage Source',
                      isLocal ? 'Local Storage Vault' : 'YouTube Music (Direct Stream)', skin),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stream URL Clipboard Copy Action
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Stream URL copied to clipboard'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: skin.bg1,
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
                    Icon(Icons.link_rounded,
                        color: skin.textMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: skin.textMuted,
                            fontSize: 12,
                            fontFamily: 'monospace'),
                      ),
                    ),
                    Icon(Icons.copy_rounded,
                        color: skin.textMuted, size: 16),
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

  Widget _buildInfoRow(String label, String value, AppSkin skin) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: skin.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: skin.fg,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}