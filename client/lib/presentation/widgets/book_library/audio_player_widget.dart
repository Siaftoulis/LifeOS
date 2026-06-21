import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../database/database.dart';
import 'audio_player_controls.dart';

class AudioPlayerWidget extends StatefulWidget {
  final Book book;
  final Audiobook audiobook;
  const AudioPlayerWidget({super.key, required this.book, required this.audiobook});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late int _currentSeconds;
  late int _durationSeconds;
  bool _isPlaying = false;
  Timer? _timer;
  int _sessionSeconds = 0;

  @override
  void initState() {
    super.initState();
    _currentSeconds = widget.audiobook.currentSeconds;
    _durationSeconds = widget.audiobook.durationSeconds > 0 ? widget.audiobook.durationSeconds : 1800; // 30 mins fallback
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying) {
        setState(() {
          if (_currentSeconds < _durationSeconds) {
            _currentSeconds++;
            _sessionSeconds++;
          } else {
            _isPlaying = false;
          }
        });
        _updateProgress();
      }
    });
  }

  Future<void> _updateProgress() async {
    final db = AppDatabase.instance;
    await db.booksDao.updateAudiobookProgress(
      widget.audiobook.id,
      _currentSeconds,
      DateTime.now().millisecondsSinceEpoch,
    );

    // Award +1 Star Point for every 15 minutes (900 seconds) of confirmed playback
    if (_sessionSeconds >= 900) {
      _sessionSeconds -= 900;
      await db.pointsDao.awardPoints(1, 'Listened 15m of ${widget.book.title}');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final h = totalSecs ~/ 3600;
    final m = (totalSecs % 3600) ~/ 60;
    final s = totalSecs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final progress = _durationSeconds > 0 ? _currentSeconds / _durationSeconds : 0.0;
    final estimatedPage = _durationSeconds > 0 
        ? ((_currentSeconds * widget.book.totalPages) / _durationSeconds).round() 
        : 1;

    return Container(
      decoration: const BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: EverforestColors.bg2, borderRadius: BorderRadius.circular(2)),
          ),
          Icon(Icons.headset, color: EverforestColors.fg, size: isMobile ? 48 : 64),
          const SizedBox(height: 16),
          Text(widget.book.title, style: const TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(widget.book.author ?? 'Unknown Author', style: const TextStyle(color: EverforestColors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Estimated Page Bookmark: $estimatedPage / ${widget.book.totalPages}', style: const TextStyle(color: EverforestColors.blue, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SliderTheme(
            data: const SliderThemeData(activeTrackColor: EverforestColors.green, inactiveTrackColor: EverforestColors.bg2, thumbColor: EverforestColors.green),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (val) {
                setState(() {
                  _currentSeconds = (val * _durationSeconds).round();
                });
                _updateProgress();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_currentSeconds), style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
              Text(_formatDuration(_durationSeconds - _currentSeconds), style: const TextStyle(color: EverforestColors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          AudioPlayerControls(
            isPlaying: _isPlaying,
            onTogglePlay: () => setState(() => _isPlaying = !_isPlaying),
            onRewind: () {
              setState(() {
                _currentSeconds = (_currentSeconds - 15).clamp(0, _durationSeconds);
              });
              _updateProgress();
            },
            onForward: () {
              setState(() {
                _currentSeconds = (_currentSeconds + 30).clamp(0, _durationSeconds);
              });
              _updateProgress();
            },
          ),
        ],
      ),
    );
  }
}
