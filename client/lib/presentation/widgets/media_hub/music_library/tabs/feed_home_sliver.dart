import 'package:flutter/material.dart';
import '../../../../../core/domain_repositories.dart';
import '../../../../../core/music_playback/playback_controller.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../components/music_cover_art.dart';
import '../music_formatters.dart';

/// Modern Home Feed blending the best of YouTube Music & Spotify:
/// - YouTube Music top Mood/Vibe filter chips
/// - YouTube Music "Quick Picks" with 1-tap instant play & radio seeding
/// - Spotify "Listen Again / Jump Back In" square cover cards carousel
/// - Spotify "Made For You & Daily Mixes" gradient mix cards
/// - "Artist Spotlight Radio" with circular artist avatar
/// - "Forgotten Favorites" rediscovery shelf
class FeedHomeSliver extends StatefulWidget {
  const FeedHomeSliver({
    super.key,
    required this.tracks,
    required this.recommendedTracks,
    required this.dailyMixTracks,
    required this.likedTracks,
    required this.canPlay,
    required this.onPlayTrack,
    required this.onPlayTrackList,
    required this.onDownloadTrack,
    required this.onAddToPlaylist,
  });

  final List<MusicTrack> tracks;
  final List<MusicTrack> recommendedTracks;
  final List<MusicTrack> dailyMixTracks;
  final List<MusicTrack> likedTracks;
  final bool canPlay;
  final void Function(MusicTrack track) onPlayTrack;
  final void Function(List<MusicTrack> list, int index) onPlayTrackList;
  final void Function(MusicTrack track) onDownloadTrack;
  final void Function(MusicTrack track) onAddToPlaylist;

  @override
  State<FeedHomeSliver> createState() => _FeedHomeSliverState();
}

class _FeedHomeSliverState extends State<FeedHomeSliver> {
  String _activeMood = 'All';

  static const List<(String id, String label, IconData icon)> _moods = [
    ('All', 'All', Icons.all_inclusive_rounded),
    ('Energize', 'Energize', Icons.bolt_rounded),
    ('Relax', 'Relax', Icons.spa_rounded),
    ('Workout', 'Workout', Icons.fitness_center_rounded),
    ('Focus', 'Focus', Icons.psychology_rounded),
    ('Greek', 'Greek Hits', Icons.account_balance_rounded),
  ];

  bool _matchesMood(MusicTrack t, String mood) {
    if (mood == 'All') return true;
    final text = '${t.title} ${t.artist} ${t.album} ${t.genre}'.toLowerCase();
    switch (mood) {
      case 'Energize':
        return text.contains('rock') ||
            text.contains('metal') ||
            text.contains('pop') ||
            text.contains('dance') ||
            text.contains('club') ||
            (t.duration > 0 && t.duration <= 210);
      case 'Relax':
        return text.contains('chill') ||
            text.contains('acoustic') ||
            text.contains('slow') ||
            text.contains('ambient') ||
            text.contains('piano') ||
            text.contains('ballad');
      case 'Workout':
        return text.contains('hip') ||
            text.contains('rap') ||
            text.contains('trap') ||
            text.contains('edm') ||
            text.contains('electronic') ||
            text.contains('gym');
      case 'Focus':
        return text.contains('lofi') ||
            text.contains('lo-fi') ||
            text.contains('instrumental') ||
            text.contains('ambient') ||
            text.contains('jazz') ||
            text.contains('study');
      case 'Greek':
        final greekRegex = RegExp(r'[\u0370-\u03FF]');
        return greekRegex.hasMatch(t.title) ||
            greekRegex.hasMatch(t.artist) ||
            text.contains('laiko') ||
            text.contains('zeimbekiko') ||
            text.contains('greek');
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final allTracks = widget.tracks;

    // Filter tracks by active mood
    final moodFiltered = _activeMood == 'All'
        ? allTracks
        : allTracks.where((t) => _matchesMood(t, _activeMood)).toList();

    // 1. Quick Picks (YouTube Music hallmark)
    final quickPicks = (widget.recommendedTracks.isNotEmpty
            ? widget.recommendedTracks
            : moodFiltered)
        .where((t) => _matchesMood(t, _activeMood))
        .take(8)
        .toList();

    // 2. Listen Again / Jump Back In (Spotify hallmark)
    final listenAgain = (moodFiltered.isNotEmpty ? moodFiltered : allTracks)
        .where((t) => t.playCount > 0 || widget.likedTracks.any((l) => l.id == t.id))
        .take(12)
        .toList();

    // If listenAgain is small, fill with recent library tracks
    final effectiveListenAgain = listenAgain.length >= 4
        ? listenAgain
        : (moodFiltered.isNotEmpty ? moodFiltered.take(10).toList() : allTracks.take(10).toList());

    // 3. Top Artist for Artist Radio
    String? topArtist;
    final artistCounts = <String, int>{};
    for (final t in allTracks) {
      final a = t.artist.trim();
      if (a.isNotEmpty && a.toLowerCase() != 'unknown' && a.toLowerCase() != 'unknown artist') {
        artistCounts[a] = (artistCounts[a] ?? 0) + 1;
      }
    }
    if (artistCounts.isNotEmpty) {
      topArtist = artistCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }
    final artistRadioTracks = topArtist != null
        ? allTracks.where((t) => t.artist.toLowerCase() == topArtist!.toLowerCase()).toList()
        : <MusicTrack>[];

    // 4. Forgotten Favorites
    final forgottenFavorites = allTracks
        .where((t) => t.playCount > 0)
        .toList()
        .reversed
        .take(8)
        .toList();

    return SliverList(
      delegate: SliverChildListDelegate([
        const SizedBox(height: 8),

        // --- YouTube Music Style Mood Pills Header ---
        _buildMoodFilterBar(skin),

        const SizedBox(height: 16),

        // --- SECTION 1: YouTube Music Style Quick Picks (Grid/List with 1-tap Play) ---
        if (quickPicks.isNotEmpty) ...[
          _buildSectionHeader(
            skin: skin,
            title: 'Quick Picks',
            subtitle: 'Start radio from any song',
            icon: Icons.flash_on_rounded,
            accentColor: skin.yellow,
            onPlayAll: () => widget.onPlayTrackList(quickPicks, 0),
          ),
          const SizedBox(height: 10),
          _buildQuickPicksGrid(skin, quickPicks),
          const SizedBox(height: 24),
        ],

        // --- SECTION 2: Spotify Style Listen Again / Jump Back In ---
        if (effectiveListenAgain.isNotEmpty) ...[
          _buildSectionHeader(
            skin: skin,
            title: 'Listen Again',
            subtitle: 'Jump back into your favorites',
            icon: Icons.replay_rounded,
            accentColor: skin.accent,
            onPlayAll: () => widget.onPlayTrackList(effectiveListenAgain, 0),
          ),
          const SizedBox(height: 10),
          _buildHorizontalCardCarousel(skin, effectiveListenAgain),
          const SizedBox(height: 24),
        ],

        // --- SECTION 3: Spotify Style Made For You & Daily Mixes ---
        _buildSectionHeader(
          skin: skin,
          title: 'Made For You',
          subtitle: 'Curated mixes tailored to your sound',
          icon: Icons.auto_awesome_rounded,
          accentColor: skin.purple,
        ),
        const SizedBox(height: 10),
        _buildDailyMixesCarousel(skin, allTracks, topArtist),
        const SizedBox(height: 24),

        // --- SECTION 4: Artist Radio / Spotlight ---
        if (topArtist != null && artistRadioTracks.isNotEmpty) ...[
          _buildArtistRadioShelf(skin, topArtist, artistRadioTracks),
          const SizedBox(height: 24),
        ],

        // --- SECTION 5: Forgotten Favorites ---
        if (forgottenFavorites.isNotEmpty) ...[
          _buildSectionHeader(
            skin: skin,
            title: 'Forgotten Favorites',
            subtitle: 'Songs you used to play on repeat',
            icon: Icons.history_rounded,
            accentColor: skin.orange,
            onPlayAll: () => widget.onPlayTrackList(forgottenFavorites, 0),
          ),
          const SizedBox(height: 10),
          _buildHorizontalCardCarousel(skin, forgottenFavorites),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 12),
      ]),
    );
  }

  // --- 1. Mood Filter Pills Bar ---
  Widget _buildMoodFilterBar(AppSkin skin) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _moods.map((m) {
          final isSelected = _activeMood == m.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                m.$3,
                size: 16,
                color: isSelected ? Colors.black : skin.textMuted,
              ),
              label: Text(m.$2),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _activeMood = m.$1);
              },
              selectedColor: skin.accent,
              backgroundColor: skin.bg1,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : skin.fg,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? skin.accent
                      : Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Section Header with Play All button ---
  Widget _buildSectionHeader({
    required AppSkin skin,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onPlayAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: skin.fg,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: skin.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (onPlayAll != null && widget.canPlay)
            TextButton.icon(
              onPressed: onPlayAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                backgroundColor: skin.bg1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
              icon: Icon(Icons.play_arrow_rounded, color: skin.accent, size: 18),
              label: Text(
                'Play All',
                style: TextStyle(
                  color: skin.fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- 2. YouTube Music Quick Picks (2-row horizontal or 4-row compact grid) ---
  Widget _buildQuickPicksGrid(AppSkin skin, List<MusicTrack> tracks) {
    // 4 items displayed in a 4-row compact list or 2-column format
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: skin.bg1.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: List.generate(tracks.length.clamp(0, 4), (i) {
            final t = tracks[i];
            final isLast = i == tracks.length.clamp(0, 4) - 1;
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.canPlay ? () => widget.onPlayTrack(t) : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Cover Art with play overlay button
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              MusicCoverArt(
                                url: t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl,
                                size: 50,
                                borderRadius: 10,
                              ),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.55),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: skin.fg,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        t.artist.isNotEmpty ? t.artist : 'LifeOS Audio',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: skin.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (t.duration > 0) ...[
                                      Text(
                                        ' · ${formatTrackDuration(t.duration)}',
                                        style: TextStyle(
                                          color: skin.textMuted,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.radio_rounded, color: skin.textMuted, size: 20),
                            tooltip: 'Start Radio',
                            onPressed: widget.canPlay ? () => widget.onPlayTrack(t) : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    thickness: 0.6,
                    color: Colors.white.withValues(alpha: 0.05),
                    indent: 76,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- 3. Spotify Style Horizontal Card Carousel ---
  Widget _buildHorizontalCardCarousel(AppSkin skin, List<MusicTrack> tracks) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tracks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final t = tracks[i];
          return MouseRegion(
            onEnter: (_) => PlaybackController.instance.precacheTrack(t.id),
            child: InkWell(
              onTap: widget.canPlay ? () => widget.onPlayTrack(t) : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 136,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: skin.bg1.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        MusicCoverArt(
                          url: t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl,
                          size: 120,
                          borderRadius: 10,
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: skin.accent,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: skin.isOled ? Colors.black : Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: skin.fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.artist.isNotEmpty ? t.artist : 'LifeOS Audio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: skin.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 4. Spotify Style Daily Mixes Carousel with Dual-Tone Gradients ---
  Widget _buildDailyMixesCarousel(AppSkin skin, List<MusicTrack> allTracks, String? topArtist) {
    final mixes = [
      (
        title: 'Daily Mix 1',
        subtitle: topArtist != null ? '$topArtist & more' : 'Your top favorites',
        gradient: const [Color(0xFF1E3A8A), Color(0xFF6B21A8)],
        icon: Icons.whatshot_rounded,
        list: widget.dailyMixTracks.isNotEmpty ? widget.dailyMixTracks : allTracks.take(20).toList(),
      ),
      (
        title: 'Daily Mix 2',
        subtitle: 'Energetic & high tempo',
        gradient: const [Color(0xFFB45309), Color(0xFFDC2626)],
        icon: Icons.bolt_rounded,
        list: allTracks.where((t) => t.duration > 0 && t.duration <= 210).take(20).toList(),
      ),
      (
        title: 'Discovery Radar',
        subtitle: 'Fresh recommendations for you',
        gradient: const [Color(0xFF065F46), Color(0xFF0D9488)],
        icon: Icons.radar_rounded,
        list: widget.recommendedTracks.isNotEmpty ? widget.recommendedTracks : allTracks.reversed.take(20).toList(),
      ),
      (
        title: 'Chill Session',
        subtitle: 'Acoustic, lo-fi & relaxing vibes',
        gradient: const [Color(0xFF312E81), Color(0xFF1E293B)],
        icon: Icons.nightlight_round,
        list: allTracks.where((t) => t.duration > 240).take(20).toList(),
      ),
    ];

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mixes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final m = mixes[i];
          return InkWell(
            onTap: widget.canPlay && m.list.isNotEmpty
                ? () => widget.onPlayTrackList(m.list, 0)
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 175,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: m.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: m.gradient.first.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(m.icon, color: Colors.white, size: 28),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 5. Artist Radio Shelf (YouTube Music style) ---
  Widget _buildArtistRadioShelf(AppSkin skin, String artist, List<MusicTrack> tracks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: skin.bg1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Circular artist avatar with glowing border
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: skin.accent, width: 2),
                  ),
                  child: ClipOval(
                    child: tracks.isNotEmpty && tracks.first.thumbnail.isNotEmpty
                        ? MusicCoverArt(
                            url: tracks.first.thumbnail,
                            size: 52,
                            borderRadius: 26,
                          )
                        : Container(
                            color: skin.accent.withValues(alpha: 0.2),
                            child: Icon(Icons.person_rounded, color: skin.accent, size: 28),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Similar to $artist',
                        style: TextStyle(
                          color: skin.fg,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Artist Radio Mix',
                        style: TextStyle(
                          color: skin.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canPlay && tracks.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => widget.onPlayTrack(tracks.first),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: skin.accent,
                      foregroundColor: skin.isOled ? Colors.black : Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    icon: const Icon(Icons.radio_rounded, size: 16),
                    label: const Text('Radio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Horizontal row of preview tracks
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tracks.length.clamp(0, 6),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final t = tracks[i];
                  return InkWell(
                    onTap: widget.canPlay ? () => widget.onPlayTrack(t) : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 180,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: skin.bg0.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          MusicCoverArt(
                            url: t.thumbnail.isNotEmpty ? t.thumbnail : t.thumbnailUrl,
                            size: 44,
                            borderRadius: 6,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  t.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: skin.fg,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  t.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: skin.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
