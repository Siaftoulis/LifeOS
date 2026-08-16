import 'package:flutter/material.dart';
import '../../../../core/domain_repositories.dart';
import '../../../../theme/everforest_colors.dart';
import 'active_session_timer_overlay.dart';
import 'youtube_player_screen.dart';

class YoutubeClientDashboard extends StatefulWidget {
  const YoutubeClientDashboard({super.key});

  @override
  State<YoutubeClientDashboard> createState() => _YoutubeClientDashboardState();
}

class _YoutubeClientDashboardState extends State<YoutubeClientDashboard> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<YoutubeVideo> _results = [];
  bool _searching = false;
  bool _loading = false;
  String _query = '';
  YoutubeSession _session = const YoutubeSession(active: false);

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final s = await YoutubeRepository.instance.sessionStatus();
    if (mounted) setState(() => _session = s);
  }

  Future<void> _search(String q) async {
    setState(() {
      _query = q;
      _searching = q.trim().isNotEmpty;
      _loading = q.trim().isNotEmpty;
    });
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    final results = await YoutubeRepository.instance.search(q);
    if (mounted && _query == q) {
      setState(() {
        _results = results;
        _loading = false;
      });
    }
  }

  Future<void> _play(YoutubeVideo v) async {
    // Watch session: starts before playback, charged when the player closes.
    final session = await YoutubeRepository.instance.sessionStart();
    if (!mounted) return;
    setState(() => _session = session);

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => YoutubePlayerScreen(video: v),
    ));
    if (!mounted) return;

    final ended = await YoutubeRepository.instance.sessionStop();
    await PointsRepository.instance.refresh();
    if (!mounted) return;
    setState(() => _session = const YoutubeSession(active: false));

    if (ended.status == 'session_ended' && ended.pointsDeducted > 0) {
      final balance = PointsRepository.instance.balance.value;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Watched ${ended.elapsedMinutes} min — -${ended.pointsDeducted} PTS. '
            'Balance: ${balance.points} pts (${balance.stars}★)'),
      ));
    }
  }

  void _download(YoutubeVideo v) {
    YoutubeRepository.instance.download(v.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading "${v.title}"...')),
    );
  }

  String _fmtDuration(int seconds) {
    if (seconds <= 0) return 'LIVE';
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EverforestColors.bg0,
      appBar: AppBar(
        backgroundColor: EverforestColors.bg1,
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled, color: EverforestColors.red, size: 28),
            SizedBox(width: 12),
            Text('YouTube Client', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold)),
          ],
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: EverforestColors.fg),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ValueListenableBuilder<PointsBalance>(
                valueListenable: PointsRepository.instance.balance,
                builder: (context, balance, _) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg2.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: EverforestColors.yellow, size: 18),
                        const SizedBox(width: 6),
                        Text('${balance.stars}★ · ${balance.points} pts',
                            style: const TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_session.active && _session.started != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ActiveSessionTimerOverlay(
                startedAt: _session.started!,
                estCost: _session.estCost,
              ),
            ),
          Expanded(child: _searching ? _buildResults() : _buildLibrary()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        style: const TextStyle(color: EverforestColors.fg, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search YouTube...',
          hintStyle: const TextStyle(color: EverforestColors.grey),
          prefixIcon: const Icon(Icons.search, color: EverforestColors.red),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, color: EverforestColors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search('');
                  },
                ),
          filled: true,
          fillColor: EverforestColors.bg1,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: EverforestColors.green));
    }
    if (_results.isEmpty) {
      return const Center(child: Text('No results', style: TextStyle(color: EverforestColors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final v = _results[i];
        return ListTile(
          leading: _thumbnail(v.thumbnail, 84, 47),
          title: Text(v.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            '${v.uploader} · ${_fmtDuration(v.duration)}',
            style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: EverforestColors.green),
                onPressed: () => _download(v),
              ),
              IconButton(
                icon: const Icon(Icons.play_circle_fill_rounded, color: EverforestColors.fg, size: 32),
                onPressed: () => _play(v),
              ),
            ],
          ),
          onTap: () => _play(v),
        );
      },
    );
  }

  Widget _buildLibrary() {
    return ValueListenableBuilder<List<YoutubeVideo>>(
      valueListenable: YoutubeRepository.instance.videos,
      builder: (context, videos, child) {
        if (videos.isEmpty) {
          return const Center(child: Text('Search above to find videos', style: TextStyle(color: EverforestColors.grey)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            childAspectRatio: 1.1,
            crossAxisSpacing: 24,
            mainAxisSpacing: 32,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            final title = video.title;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.play_arrow, size: 64, color: EverforestColors.fg),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: EverforestColors.bg2,
                      radius: 20,
                      child: Text(
                        title.isNotEmpty ? title[0] : 'Y',
                        style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Size: ${video.size}',
                              style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert, color: EverforestColors.grey),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _thumbnail(String url, double w, double h) {
    if (url.isEmpty) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.play_arrow, color: EverforestColors.red),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(url, width: w, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
                width: w,
                height: h,
                color: EverforestColors.bg1,
                child: const Icon(Icons.play_arrow, color: EverforestColors.red),
              )),
    );
  }
}