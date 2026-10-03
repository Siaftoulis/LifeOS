import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../../../../core/services/local_audio_metadata_service.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../music_formatters.dart';

/// Unified audiophile cover art widget that seamlessly supports:
/// 1. Remote HTTP/HTTPS image URLs
/// 2. Local device image files (`.jpg`, `.png`, etc.)
/// 3. Local audio files (`.mp3`, `.m4a`, etc.) with embedded ID3 APIC extraction
/// 4. Android device audio (`phone_<id>`) via [QueryArtworkWidget]
/// 5. `file://` URIs and `data:image/...;base64,...` data URIs
/// 6. Audiophile gradient fallback matched to the active skin
class MusicCoverArt extends StatelessWidget {
  final String? url;
  final String? trackId;
  final String? filePath;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? fallback;
  final bool showShadow;

  const MusicCoverArt({
    super.key,
    required this.url,
    this.trackId,
    this.filePath,
    this.size = 48,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.fallback,
    this.showShadow = true,
  });

  static final Map<String, Uint8List?> _extractedCoverCache = {};

  static bool _isAudioExtension(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.opus') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wma');
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final rawUrl = (url ?? '').trim();
    final effectiveTrackId = (trackId ?? '').trim();
    final effectiveFilePath = (filePath ?? '').trim();

    final imageWidget = _buildImage(rawUrl, effectiveTrackId, effectiveFilePath, skin);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: skin.isOled ? 0.6 : 0.25),
                  blurRadius: size > 80 ? 16 : 6,
                  offset: Offset(0, size > 80 ? 6 : 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      ),
    );
  }

  Widget _buildImage(String pathOrUrl, String trackId, String filePath, AppSkin skin) {
    // 1. Android MediaStore Audio Artwork (for phone songs)
    if (!kIsWeb && Platform.isAndroid) {
      String? phoneIdStr;
      if (trackId.startsWith('phone_')) {
        phoneIdStr = trackId.substring(6);
      } else if (pathOrUrl.startsWith('phone_')) {
        phoneIdStr = pathOrUrl.substring(6);
      }
      if (phoneIdStr != null) {
        final songId = int.tryParse(phoneIdStr);
        if (songId != null) {
          return QueryArtworkWidget(
            id: songId,
            type: ArtworkType.AUDIO,
            artworkWidth: size,
            artworkHeight: size,
            artworkBorder: BorderRadius.circular(borderRadius),
            artworkFit: fit,
            nullArtworkWidget: _buildFallback(skin),
            errorBuilder: (_, __, ___) => _buildFallback(skin),
          );
        }
      }
    }

    // 2. Data URI (Base64)
    if (pathOrUrl.startsWith('data:image')) {
      try {
        final commaIdx = pathOrUrl.indexOf(',');
        if (commaIdx != -1) {
          final b64 = pathOrUrl.substring(commaIdx + 1);
          final bytes = base64Decode(b64);
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(skin),
          );
        }
      } catch (_) {
        return _buildFallback(skin);
      }
    }

    // 3. HTTP / HTTPS Network URL
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      final sanitized = sanitizeMusicThumbnailUrl(pathOrUrl);
      return Image.network(
        sanitized,
        width: size,
        height: size,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => _buildFallback(skin),
      );
    }

    // 4. Local File System handling (Image file vs Embedded Audio metadata)
    if (!kIsWeb) {
      String candidatePath = pathOrUrl;
      if (candidatePath.startsWith('file://')) {
        try {
          candidatePath = Uri.parse(candidatePath).toFilePath();
        } catch (_) {}
      }
      if (candidatePath.isEmpty && filePath.isNotEmpty) {
        candidatePath = filePath.startsWith('file://')
            ? Uri.parse(filePath).toFilePath()
            : filePath;
      }

      if (candidatePath.isNotEmpty) {
        // 4a. If candidatePath is an audio file, extract embedded cover art
        if (_isAudioExtension(candidatePath)) {
          if (_extractedCoverCache.containsKey(candidatePath)) {
            final cachedBytes = _extractedCoverCache[candidatePath];
            if (cachedBytes != null && cachedBytes.isNotEmpty) {
              return Image.memory(
                cachedBytes,
                width: size,
                height: size,
                fit: fit,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => _buildFallback(skin),
              );
            }
            return _buildFallback(skin);
          }

          return FutureBuilder<Uint8List?>(
            future: _loadEmbeddedCover(candidatePath),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data != null &&
                  snapshot.data!.isNotEmpty) {
                return Image.memory(
                  snapshot.data!,
                  width: size,
                  height: size,
                  fit: fit,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => _buildFallback(skin),
                );
              }
              return _buildFallback(skin);
            },
          );
        }

        // 4b. If candidatePath is an image file on disk
        try {
          final file = File(candidatePath);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: size,
              height: size,
              fit: fit,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => _buildFallback(skin),
            );
          }
        } catch (_) {}
      }
    }

    return _buildFallback(skin);
  }

  Future<Uint8List?> _loadEmbeddedCover(String audioPath) async {
    try {
      final file = File(audioPath);
      if (!await file.exists()) {
        _extractedCoverCache[audioPath] = null;
        return null;
      }
      final meta = await LocalAudioMetadataService.instance.readMetadata(file);
      final bytes = meta.coverBytes;
      _extractedCoverCache[audioPath] = bytes;
      return bytes;
    } catch (_) {
      _extractedCoverCache[audioPath] = null;
      return null;
    }
  }

  Widget _buildFallback(AppSkin skin) {
    if (fallback != null) return fallback!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            skin.bg2,
            skin.bg1,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: skin.blue.withValues(alpha: 0.85),
          size: (size * 0.45).clamp(16.0, 48.0),
        ),
      ),
    );
  }
}
