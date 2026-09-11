import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../core/music_playback/playback_models.dart';
import '../../../../../database/database.dart' hide MusicTrack;
import '../../../../../theme/app_skin_manager.dart';
import '../components/heart_button.dart';
import '../components/poweramp_track_context_sheet.dart';
import '../music_formatters.dart';
import 'all_tracks_sliver.dart';

class OfflineTracksSliver extends StatefulWidget {
  const OfflineTracksSliver({
    super.key,
    required this.currentTrackId,
    required this.canPlay,
    required this.playbackController,
    required this.onDeleteOffline,
    required this.onWebNotice,
    required this.streamUrlFor,
  });

  final String currentTrackId;
  final bool canPlay;
  final PlaybackController playbackController;
  final void Function(OfflineMusicTrack track) onDeleteOffline;
  final VoidCallback onWebNotice;
  final String Function(String trackId) streamUrlFor;

  @override
  State<OfflineTracksSliver> createState() => _OfflineTracksSliverState();
}

class _OfflineTracksSliverState extends State<OfflineTracksSliver> {
  bool _isScanning = false;
  String _scanStatus = '';
  double _scanProgress = 0.0;

  Future<void> _pickAndScanFolder() async {
    if (kIsWeb) return;
    try {
      final selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Local Music Folder',
      );
      if (selectedDir == null || selectedDir.isEmpty) return;

      setState(() {
        _isScanning = true;
        _scanStatus = 'Scanning music folder...';
        _scanProgress = 0.0;
      });

      final count = await MusicRepository.instance.scanLocalDirectory(
        selectedDir,
        onProgress: (curr, total, name) {
          if (mounted) {
            setState(() {
              _scanProgress = total > 0 ? (curr / total) : 0.0;
              _scanStatus = '$curr / $total: $name';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Imported $count local track${count == 1 ? '' : 's'} with metadata & cover art'
                : 'No supported audio files found in selected folder'),
            backgroundColor: count > 0 ? context.skin.accent : context.skin.bg1,
          ),
        );
      }
    } catch (e) {
      debugPrint('Folder scan error: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan folder: $e'),
            backgroundColor: context.skin.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAudioFiles() async {
    if (kIsWeb) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Audio Files',
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'flac', 'wav', 'ogg', 'aac', 'opus'],
        allowMultiple: true,
      );

      if (result == null || result.paths.isEmpty) return;
      final validPaths = result.paths.whereType<String>().toList();
      if (validPaths.isEmpty) return;

      setState(() {
        _isScanning = true;
        _scanStatus = 'Importing audio files...';
        _scanProgress = 0.0;
      });

      final count = await MusicRepository.instance.importLocalAudioFiles(
        validPaths,
        onProgress: (curr, total, name) {
          if (mounted) {
            setState(() {
              _scanProgress = total > 0 ? (curr / total) : 0.0;
              _scanStatus = '$curr / $total: $name';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count audio track${count == 1 ? '' : 's'} with metadata & cover art'),
            backgroundColor: context.skin.accent,
          ),
        );
      }
    } catch (e) {
      debugPrint('File pick error: $e');
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import audio files: $e'),
            backgroundColor: context.skin.red,
          ),
        );
      }
    }
  }

  Future<void> _quickScanWindowsMusic() async {
    if (kIsWeb || !Platform.isWindows) return;
    try {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile == null) return;
      final musicPath = '$userProfile\\Music';
      final musicDir = Directory(musicPath);
      if (!await musicDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Music directory not found at $musicPath'),
            backgroundColor: context.skin.bg1,
          ),
        );
        return;
      }

      setState(() {
        _isScanning = true;
        _scanStatus = 'Scanning Windows Music folder...';
        _scanProgress = 0.0;
      });

      final count = await MusicRepository.instance.scanLocalDirectory(
        musicPath,
        onProgress: (curr, total, name) {
          if (mounted) {
            setState(() {
              _scanProgress = total > 0 ? (curr / total) : 0.0;
              _scanStatus = '$curr / $total: $name';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count tracks from Windows Music library'),
            backgroundColor: context.skin.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanStatus = '';
        });
      }
    }
  }

  Widget _buildScanHeader(AppSkin skin, int trackCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: skin.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.devices_rounded, color: skin.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Local & Offline Vault ($trackCount tracks)',
                  style: TextStyle(
                    color: skin.fg,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Play local audio files directly from this device with extracted ID3 metadata and album art — 100% offline.',
            style: TextStyle(color: skin.textMuted, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _isScanning ? null : _pickAndScanFolder,
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: const Text('Scan Folder'),
                style: FilledButton.styleFrom(
                  backgroundColor: skin.accent.withValues(alpha: 0.2),
                  foregroundColor: skin.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isScanning ? null : _pickAudioFiles,
                icon: const Icon(Icons.audio_file_rounded, size: 16),
                label: const Text('Add Files'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: skin.fg,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (trackCount > 0 && widget.canPlay)
                FilledButton.icon(
                  onPressed: () async {
                    final list = MusicRepository.instance.offlineTracks.value;
                    if (list.isEmpty) return;
                    final seed = (List.of(list)..shuffle()).first;
                    final item = PlaybackItem(
                      id: seed.id,
                      url: seed.filePath,
                      title: seed.title,
                      artist: seed.artist ?? 'Unknown',
                      thumbnail: seed.thumbnail ?? '',
                      album: seed.album ?? '',
                      filePath: seed.filePath,
                    );
                    await widget.playbackController.playTrackAndStartRadio(item);
                  },
                  icon: const Icon(Icons.sensors_rounded, size: 16),
                  label: const Text('Start Offline Radio'),
                  style: FilledButton.styleFrom(
                    backgroundColor: skin.yellow.withValues(alpha: 0.18),
                    foregroundColor: skin.yellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              if (!kIsWeb && Platform.isWindows)
                TextButton.icon(
                  onPressed: _isScanning ? null : _quickScanWindowsMusic,
                  icon: Icon(Icons.music_note_rounded, size: 16, color: skin.blue),
                  label: Text('Windows Music Folder', style: TextStyle(color: skin.blue)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          if (_isScanning) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _scanProgress > 0 ? _scanProgress : null,
                backgroundColor: skin.bg2,
                valueColor: AlwaysStoppedAnimation<Color>(skin.accent),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _scanStatus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: skin.textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return ValueListenableBuilder<List<OfflineMusicTrack>>(
      valueListenable: MusicRepository.instance.offlineTracks,
      builder: (context, list, _) {
        if (list.isEmpty) {
          return SliverMainAxisGroup(
            slivers: [
              SliverToBoxAdapter(child: _buildScanHeader(skin, 0)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.album_rounded, size: 54, color: skin.textMuted.withValues(alpha: 0.4)),
                        const SizedBox(height: 14),
                        Text(
                          'No local tracks imported yet.\nScan a music folder or pick audio files to make them\nplayable offline with full album cover art.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: skin.textMuted,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(child: _buildScanHeader(skin, list.length)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final o = list[i];
                  final isPlaying = widget.currentTrackId == o.id;
                  final isLocalFile = o.id.startsWith('local_') ||
                      (o.filePath.length > 2 && o.filePath[1] == ':') ||
                      (!kIsWeb && o.filePath.startsWith('/') && !o.filePath.startsWith('/api/'));

                  final track = MusicTrack(
                    id: o.id,
                    title: o.title,
                    artist: o.artist ?? 'Unknown',
                    album: o.album ?? '',
                    thumbnail: o.thumbnail ?? '',
                    thumbnailUrl: o.thumbnail ?? '',
                    filePath: o.filePath,
                    duration: o.duration.toDouble(),
                  );

                  final playQueue = list
                      .map((x) => PlaybackItem(
                            id: x.id,
                            url: x.filePath.isNotEmpty
                                ? x.filePath
                                : widget.streamUrlFor(x.id),
                            title: x.title,
                            artist: x.artist ?? '',
                            thumbnail: x.thumbnail ?? '',
                            album: x.album ?? '',
                            filePath: x.filePath,
                          ))
                      .toList();

                  return ListTile(
                    leading: Stack(
                      children: [
                        TrackThumbnail(url: o.thumbnail ?? '', size: 48),
                        if (isPlaying)
                          Positioned(
                            right: 2,
                            bottom: 2,
                            child: Icon(Icons.graphic_eq_rounded,
                                color: skin.accent, size: 16),
                          ),
                      ],
                    ),
                    title: Text(
                      o.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isPlaying ? skin.accent : skin.fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${o.artist ?? 'Unknown'}${o.album != null && o.album!.isNotEmpty ? ' · ${o.album}' : ''}${o.duration > 0 ? ' · ${formatTrackDuration(o.duration)}' : ''} · ${isLocalFile ? '📱 Local File' : '💾 Vault'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: skin.textMuted, fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HeartButton(track: track),
                        IconButton(
                          icon: Icon(Icons.more_vert_rounded,
                              color: skin.textMuted, size: 20),
                          tooltip: 'Track actions',
                          onPressed: () => PowerampTrackContextSheet.show(
                            context,
                            track: track,
                            onDelete: () => widget.onDeleteOffline(o),
                          ),
                        ),
                        if (widget.canPlay)
                          IconButton(
                            icon: Icon(Icons.play_circle_fill_rounded,
                                color: skin.fg, size: 32),
                            onPressed: () => widget.playbackController
                                .playQueue(playQueue, startIndex: i),
                          )
                        else
                          Tooltip(
                            message: 'Playback is available in the LifeOS native app',
                            child: Icon(Icons.phonelink_lock_rounded,
                                color: skin.textMuted, size: 20),
                          ),
                      ],
                    ),
                    onTap: widget.canPlay
                        ? () => widget.playbackController
                            .playQueue(playQueue, startIndex: i)
                        : widget.onWebNotice,
                    onLongPress: () => PowerampTrackContextSheet.show(
                      context,
                      track: track,
                      onDelete: () => widget.onDeleteOffline(o),
                    ),
                  );
                },
                childCount: list.length,
              ),
            ),
          ],
        );
      },
    );
  }
}

class PhoneSongsSliver extends StatelessWidget {
  const PhoneSongsSliver({
    super.key,
    required this.phoneSongs,
    required this.playbackController,
  });

  final List<SongModel> phoneSongs;
  final PlaybackController playbackController;

  String _fmt(double ms) {
    final s = (ms / 1000).round();
    final m = s ~/ 60;
    final remS = s % 60;
    return '$m:${remS.toString().padLeft(2, '0')}';
  }

  Future<void> _importAllToVault(BuildContext context) async {
    final paths = phoneSongs
        .map((s) => s.data)
        .where((p) => p.isNotEmpty)
        .toList();
    if (paths.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Importing ${paths.length} device songs to vault...'),
        backgroundColor: context.skin.bg1,
      ),
    );

    final count = await MusicRepository.instance.importLocalAudioFiles(paths);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $count phone songs into local library'),
          backgroundColor: context.skin.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'On This Phone (${phoneSongs.length})',
                    style: TextStyle(
                      color: skin.fg,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _importAllToVault(context),
                  icon: const Icon(Icons.download_done_rounded, size: 16),
                  label: const Text('Index All'),
                  style: TextButton.styleFrom(
                    foregroundColor: skin.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final s = phoneSongs[i];

              final phoneQueue = phoneSongs.map((x) {
                final p = (x.data.isNotEmpty) ? x.data : (x.uri ?? '');
                return PlaybackItem(
                  id: 'phone_${x.id}',
                  url: p,
                  title: x.title,
                  artist: x.artist ?? '',
                  thumbnail: '',
                  album: x.album ?? '',
                  filePath: x.data,
                );
              }).toList();

              final track = MusicTrack(
                id: 'phone_${s.id}',
                title: s.title,
                artist: s.artist ?? 'Unknown',
                album: s.album ?? '',
                thumbnail: '',
                thumbnailUrl: '',
                filePath: s.data.isNotEmpty ? s.data : (s.uri ?? ''),
                duration: (s.duration ?? 0) / 1000,
              );

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: QueryArtworkWidget(
                      id: s.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 48,
                      artworkHeight: 48,
                      artworkBorder: BorderRadius.circular(8),
                      nullArtworkWidget: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: skin.bg1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.music_note_rounded,
                            color: skin.blue, size: 24),
                      ),
                    ),
                  ),
                ),
                title: Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: skin.fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${s.artist ?? 'Unknown'} · ${_fmt((s.duration ?? 0).toDouble())}',
                  style: TextStyle(color: skin.textMuted, fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HeartButton(track: track),
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded,
                          color: skin.textMuted, size: 20),
                      tooltip: 'Track actions',
                      onPressed: () => PowerampTrackContextSheet.show(
                        context,
                        track: track,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.play_circle_fill_rounded,
                          color: skin.fg, size: 32),
                      onPressed: () =>
                          playbackController.playQueue(phoneQueue, startIndex: i),
                    ),
                  ],
                ),
                onTap: () =>
                    playbackController.playQueue(phoneQueue, startIndex: i),
                onLongPress: () => PowerampTrackContextSheet.show(
                  context,
                  track: track,
                ),
              );
            },
            childCount: phoneSongs.length,
          ),
        ),
      ],
    );
  }
}
