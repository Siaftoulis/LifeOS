import 'package:flutter/material.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../core/music_playback/playback_controller.dart';
import '../../../../theme/app_skin_manager.dart';
import 'components/download_quality_dialog.dart';
import 'components/poweramp_track_context_sheet.dart';
import 'music_formatters.dart';

/// 1:1 Poweramp Search & Grouped Categories Screen matching Screenshots 2 & 3.
class PowerampSearchView extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;
  final void Function(MusicTrack track) onPlayTrack;
  final List<MusicTrack>? remoteResults;
  final bool isSearching;

  const PowerampSearchView({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onClear,
    required this.onPlayTrack,
    this.onPlayTrackList,
    this.remoteResults,
    this.isSearching = false,
  });

  final void Function(List<MusicTrack> tracks, int index)? onPlayTrackList;

  @override
  State<PowerampSearchView> createState() => _PowerampSearchViewState();
}

class _PowerampSearchViewState extends State<PowerampSearchView> {
  int _selectedFilterIndex = 0; // 0: All, 1: Albums, 2: Artists, 3: Album Artists, 4: Folders, 5: Genres
  bool _selectionMode = false;
  final Set<String> _selectedTrackIds = {};

  final List<String> _categories = [
    'All',
    'YouTube Music',
    'Albums',
    'Artists',
    'Album Artists',
    'Folders',
    'Genres',
  ];

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final query = widget.controller.text.trim().toLowerCase();

    return ValueListenableBuilder<List<MusicTrack>>(
      valueListenable: MusicRepository.instance.tracks,
      builder: (context, allTracks, _) {
        // Filter tracks according to search query
        final matchingTracks = query.isEmpty
            ? allTracks
            : allTracks.where((t) {
                final matchTitle = t.title.toLowerCase().contains(query);
                final matchArtist = t.artist.toLowerCase().contains(query);
                final matchAlbum = t.album.toLowerCase().contains(query);
                return matchTitle || matchArtist || matchAlbum;
              }).toList();

        final existingIds = matchingTracks.map((t) => t.id).toSet();
        final combinedTracks = [
          ...matchingTracks,
          if (widget.remoteResults != null)
            ...widget.remoteResults!.where((t) => !existingIds.contains(t.id)),
        ];

        // Group into Albums
        final Map<String, List<MusicTrack>> albumsMap = {};
        for (final t in combinedTracks) {
          final alb = t.album.trim().isNotEmpty ? t.album.trim() : 'Unknown Album';
          albumsMap.putIfAbsent(alb, () => []).add(t);
        }

        // Group into Artists
        final Map<String, List<MusicTrack>> artistsMap = {};
        for (final t in combinedTracks) {
          final art = t.artist.trim().isNotEmpty ? t.artist.trim() : 'Unknown Artist';
          artistsMap.putIfAbsent(art, () => []).add(t);
        }

        return Column(
          children: [
            // Top Search Input Box (matching Screenshots 2 & 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: skin.bg1,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Icon(Icons.search_rounded, color: skin.fg, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search songs, albums, artists...',
                          hintStyle: TextStyle(color: skin.textMuted, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {});
                          widget.onQueryChanged(val);
                        },
                        onSubmitted: (val) {
                          setState(() {});
                          widget.onQueryChanged(val);
                        },
                      ),
                    ),
                    if (widget.controller.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: skin.textMuted, size: 20),
                        onPressed: () {
                          widget.onClear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (widget.isSearching)
              const LinearProgressIndicator(minHeight: 2),

            // Category Filter Pills Carousel
            SizedBox(
              height: 38,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedFilterIndex == index;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.white.withValues(alpha: 0.18),
                    backgroundColor: skin.bg1,
                    side: BorderSide(
                      color: isSelected ? Colors.white30 : Colors.transparent,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? skin.fg : skin.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedFilterIndex = index);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Quick Actions Bar: [ Shuffle ] [ Play ] [ Select ] [ ⋮ ]
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: Icons.shuffle_rounded,
                    skin: skin,
                    onTap: () {
                      if (combinedTracks.isNotEmpty) {
                        final shuffled = List<MusicTrack>.from(combinedTracks)..shuffle();
                        widget.onPlayTrack(shuffled.first);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.play_arrow_rounded,
                    skin: skin,
                    onTap: () {
                      if (combinedTracks.isNotEmpty) {
                        widget.onPlayTrack(combinedTracks.first);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildPillActionButton(
                    label: _selectionMode ? 'Done' : 'Select',
                    isActive: _selectionMode,
                    skin: skin,
                    onTap: () {
                      setState(() {
                        _selectionMode = !_selectionMode;
                        if (!_selectionMode) _selectedTrackIds.clear();
                      });
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.more_vert_rounded, color: skin.textMuted, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Colors.white10),

            // Grouped Results List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                children: [
                  // 0. YouTube Music Online Section (shown when All or YouTube Music is selected)
                  if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 1) &&
                      widget.remoteResults != null &&
                      widget.remoteResults!.isNotEmpty) ...[
                    _buildSectionHeader('YouTube Music Online', skin),
                    ...widget.remoteResults!.map((t) => _buildRemoteTrackTile(t, skin)),
                    const SizedBox(height: 12),
                  ] else if (widget.isSearching && (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: skin.accent, strokeWidth: 2.2),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Searching YouTube Music Online...',
                              style: TextStyle(color: skin.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_selectedFilterIndex == 1) ...[
                    if (widget.isSearching)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: skin.accent),
                              const SizedBox(height: 12),
                              Text(
                                'Searching YouTube Music...',
                                style: TextStyle(color: skin.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.travel_explore_rounded, size: 48, color: skin.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'Search YouTube Music for online tracks, remixes & albums',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: skin.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],

                  // 1. Albums Section
                  if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 2) &&
                      albumsMap.isNotEmpty) ...[
                    _buildSectionHeader('Albums', skin),
                    ...albumsMap.entries.take(5).map((e) {
                      final albumTracks = e.value;
                      final first = albumTracks.first;
                      final totalSec = albumTracks.fold<double>(0.0, (acc, t) => acc + t.duration);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: skin.bg2,
                            child: first.thumbnail.isNotEmpty
                                ? Image.network(
                                    sanitizeMusicThumbnailUrl(first.thumbnail),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.album_rounded, color: skin.accent, size: 24),
                                  )
                                : Icon(Icons.album_rounded, color: skin.accent, size: 24),
                          ),
                        ),
                        title: Text(
                          e.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: skin.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          '${first.artist.isNotEmpty ? first.artist : "Unknown Artist"}\n♪ ${albumTracks.length} | ${formatTrackDuration(totalSec)}',
                          style: TextStyle(color: skin.textMuted, fontSize: 11.5),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          if (albumTracks.isNotEmpty) widget.onPlayTrack(albumTracks.first);
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // 2. Artists Section
                  if ((_selectedFilterIndex == 0 || _selectedFilterIndex == 3) &&
                      artistsMap.isNotEmpty) ...[
                    _buildSectionHeader('Artists', skin),
                    ...artistsMap.entries.take(4).map((e) {
                      final artTracks = e.value;
                      final first = artTracks.first;
                      final totalSec = artTracks.fold<double>(0.0, (acc, t) => acc + t.duration);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: skin.bg2,
                          backgroundImage: first.thumbnail.isNotEmpty
                              ? NetworkImage(sanitizeMusicThumbnailUrl(first.thumbnail))
                              : null,
                          child: first.thumbnail.isEmpty
                              ? Icon(Icons.person_rounded, color: skin.accent, size: 24)
                              : null,
                        ),
                        title: Text(
                          e.key,
                          style: TextStyle(
                            color: skin.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                          ),
                        ),
                        subtitle: Text(
                          '♪ ${artTracks.length} | ${formatTrackDuration(totalSec)}',
                          style: TextStyle(color: skin.textMuted, fontSize: 11.5),
                        ),
                        onTap: () {
                          if (artTracks.isNotEmpty) widget.onPlayTrack(artTracks.first);
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],

                  // 3. All Songs Section
                  if (_selectedFilterIndex == 0 || _selectedFilterIndex >= 4) ...[
                    _buildSectionHeader('All Songs', skin),
                    ...combinedTracks.map((t) {
                      final isSelected = _selectedTrackIds.contains(t.id);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 2),
                        leading: _selectionMode
                            ? Checkbox(
                                value: isSelected,
                                activeColor: skin.accent,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedTrackIds.add(t.id);
                                    } else {
                                      _selectedTrackIds.remove(t.id);
                                    }
                                  });
                                },
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  color: skin.bg2,
                                  child: t.thumbnail.isNotEmpty
                                      ? Image.network(
                                          sanitizeMusicThumbnailUrl(t.thumbnail),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.music_note_rounded,
                                            color: skin.accent,
                                            size: 22,
                                          ),
                                        )
                                      : Icon(
                                          Icons.music_note_rounded,
                                          color: skin.accent,
                                          size: 22,
                                        ),
                                ),
                              ),
                        title: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: skin.fg,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '${t.artist.isNotEmpty ? t.artist : "Unknown"} · ${formatTrackDuration(t.duration)} | audio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: skin.textMuted, fontSize: 11.5),
                        ),
                        onTap: () {
                          if (_selectionMode) {
                            setState(() {
                              if (isSelected) {
                                _selectedTrackIds.remove(t.id);
                              } else {
                                _selectedTrackIds.add(t.id);
                              }
                            });
                          } else {
                            if (widget.onPlayTrackList != null) {
                              final idx = combinedTracks.indexOf(t);
                              widget.onPlayTrackList!(combinedTracks, idx >= 0 ? idx : 0);
                            } else {
                              widget.onPlayTrack(t);
                            }
                          }
                        },
                        onLongPress: () {
                          PowerampTrackContextSheet.show(context, track: t);
                        },
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRemoteTrackTile(MusicTrack t, AppSkin skin) {
    return MouseRegion(
      onEnter: (_) => PlaybackController.instance.precacheTrack(t.id),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: 44,
                height: 44,
                color: skin.bg2,
                child: t.thumbnail.isNotEmpty
                    ? Image.network(
                        sanitizeMusicThumbnailUrl(t.thumbnail),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note_rounded,
                          color: skin.accent,
                          size: 22,
                        ),
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        color: skin.accent,
                        size: 22,
                      ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 10),
              ),
            ),
          ],
        ),
        title: Text(
          t.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: skin.fg,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: skin.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: skin.accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'YTM ONLINE',
                style: TextStyle(color: skin.accent, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${t.artist.isNotEmpty ? t.artist : "YouTube Music"}${t.duration > 0 ? " · ${formatTrackDuration(t.duration)}" : ""}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: skin.textMuted, fontSize: 11.5),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, size: 20),
          color: skin.accent,
          tooltip: 'Download to LifeOS library',
          onPressed: () async {
            final mode = await DownloadQualitySheet.show(context, track: t);
            if (mode == null) return;
            MusicRepository.instance.download(t, qualityMode: mode);
            if (context.mounted) {
              final label = mode == 'best' ? 'Lossless/HQ' : 'Fast';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading "${t.title}" ($label)...'),
                  backgroundColor: skin.bg1,
                ),
              );
            }
          },
        ),
        onTap: () {
          final rem = widget.remoteResults ?? [t];
          if (widget.onPlayTrackList != null) {
            final idx = rem.indexOf(t);
            widget.onPlayTrackList!(rem, idx >= 0 ? idx : 0);
          } else {
            widget.onPlayTrack(t);
          }
        },
        onLongPress: () {
          PowerampTrackContextSheet.show(context, track: t);
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppSkin skin) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: skin.fg,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 0.8,
              color: Colors.white12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required AppSkin skin,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: skin.bg1,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: skin.fg, size: 20),
        ),
      ),
    );
  }

  Widget _buildPillActionButton({
    required String label,
    required bool isActive,
    required AppSkin skin,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? skin.accent.withValues(alpha: 0.2) : skin.bg1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? skin.accent : Colors.white12,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? skin.accent : skin.fg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
