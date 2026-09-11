import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../../theme/app_skin_manager.dart';
import '../music_formatters.dart';

/// Unified audiophile cover art widget that seamlessly supports:
/// 1. Remote HTTP/HTTPS image URLs
/// 2. Local device files (Windows `C:\...`, Android/Linux `/storage/...` or `/...`)
/// 3. `file://` URIs
/// 4. `data:image/...;base64,...` data URIs
/// 5. Audiophile gradient fallback matched to the active skin
class MusicCoverArt extends StatelessWidget {
  final String? url;
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Widget? fallback;
  final bool showShadow;

  const MusicCoverArt({
    super.key,
    required this.url,
    this.size = 48,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.fallback,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;
    final rawUrl = (url ?? '').trim();

    final imageWidget = _buildImage(rawUrl, skin);

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

  Widget _buildImage(String pathOrUrl, AppSkin skin) {
    if (pathOrUrl.isEmpty) {
      return _buildFallback(skin);
    }

    // 1. Data URI (Base64)
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

    // 2. HTTP / HTTPS Network URL
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      final sanitized = sanitizeMusicThumbnailUrl(pathOrUrl);
      return Image.network(
        sanitized,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(skin),
      );
    }

    // 3. Local File System (`file://`, `C:\...`, or `/...`)
    if (!kIsWeb) {
      try {
        String cleanPath = pathOrUrl;
        if (cleanPath.startsWith('file://')) {
          cleanPath = Uri.parse(cleanPath).toFilePath();
        }
        final file = File(cleanPath);
        if (file.existsSync()) {
          return Image.file(
            file,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, __, ___) => _buildFallback(skin),
          );
        }
      } catch (_) {
        // file access or path error -> fallback
      }
    }

    return _buildFallback(skin);
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
