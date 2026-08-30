import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../api_client.dart';
import '../../../core/chat/chat_models.dart';
import '../../../theme/everforest_colors.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;

  const VoiceMessagePlayer({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  AudioPlayer? _player;
  bool _isPlaying = false;
  Duration _duration = const Duration(seconds: 12);
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  List<double> _waveformAmplitudes = [];

  @override
  void initState() {
    super.initState();
    _initWaveform();
    _initAudioPlayer();
  }

  void _initWaveform() {
    // Generate a deterministic aesthetic waveform based on message ID hash
    final seed = widget.message.id.hashCode;
    final random = Random(seed);
    _waveformAmplitudes = List.generate(24, (_) => (random.nextDouble() * 0.7) + 0.3);
  }

  Future<void> _initAudioPlayer() async {
    final url = widget.message.attachmentURL;
    if (url == null || url.isEmpty) return;

    try {
      _player = AudioPlayer();
      final fullUrl = url.startsWith('http') ? url : '${ApiClient.instance.daemonUrl}$url';
      
      _player!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing && state.processingState != ProcessingState.completed;
            if (state.processingState == ProcessingState.completed) {
              _position = Duration.zero;
            }
          });
        }
      });

      _player!.positionStream.listen((pos) {
        if (mounted) {
          setState(() => _position = pos);
        }
      });

      _player!.durationStream.listen((dur) {
        if (mounted && dur != null) {
          setState(() => _duration = dur);
        }
      });

      // Prepare audio source
      await _player!.setUrl(fullUrl);
    } catch (_) {
      // Defensive fallback for offline mock / test environments
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_player != null) {
      if (_isPlaying) {
        await _player!.pause();
      } else {
        if (_position >= _duration) {
          await _player!.seek(Duration.zero);
        }
        await _player!.play();
      }
    } else {
      // Mock playback simulation for tests or non-networked environments
      setState(() => _isPlaying = !_isPlaying);
    }
  }

  void _toggleSpeed() {
    double nextSpeed = 1.0;
    if (_playbackSpeed == 1.0) nextSpeed = 1.5;
    else if (_playbackSpeed == 1.5) nextSpeed = 2.0;
    else nextSpeed = 1.0;

    setState(() => _playbackSpeed = nextSpeed);
    _player?.setSpeed(nextSpeed);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString();
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final baseColor = widget.isMe ? EverforestColors.bg0 : EverforestColors.fg;
    final accentColor = widget.isMe ? EverforestColors.bg0.withValues(alpha: 0.8) : EverforestColors.green;

    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play/Pause Button
              InkWell(
                onTap: _togglePlay,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.isMe ? EverforestColors.bg0.withValues(alpha: 0.25) : EverforestColors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: baseColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Waveform Bars
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: List.generate(_waveformAmplitudes.length, (index) {
                      final barProgress = index / _waveformAmplitudes.length;
                      final isPlayed = barProgress <= progressFraction;

                      return Container(
                        width: 3,
                        height: 26 * _waveformAmplitudes[index],
                        decoration: BoxDecoration(
                          color: isPlayed
                              ? accentColor
                              : (widget.isMe ? EverforestColors.bg0.withValues(alpha: 0.35) : EverforestColors.bg2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Playback Speed Button
              InkWell(
                onTap: _toggleSpeed,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.isMe ? EverforestColors.bg0.withValues(alpha: 0.2) : EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: widget.isMe ? EverforestColors.bg0.withValues(alpha: 0.4) : EverforestColors.bg2),
                  ),
                  child: Text(
                    '${_playbackSpeed}x',
                    style: TextStyle(
                      color: baseColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Timer text
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Text(
              _isPlaying ? _formatDuration(_position) : _formatDuration(_duration),
              style: TextStyle(
                color: widget.isMe ? EverforestColors.bg0.withValues(alpha: 0.7) : EverforestColors.grey,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
