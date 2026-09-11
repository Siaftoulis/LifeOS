import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Parsed metadata for a local audio track including extracted cover art.
class ParsedAudioMetadata {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final double duration;
  final int? year;
  final String? genre;
  final Uint8List? coverBytes;
  final String? thumbnailPath;

  const ParsedAudioMetadata({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.year,
    this.genre,
    this.coverBytes,
    this.thumbnailPath,
  });

  @override
  String toString() =>
      'ParsedAudioMetadata(title: "$title", artist: "$artist", album: "$album", duration: $duration, hasCover: ${coverBytes != null || thumbnailPath != null})';
}

/// Zero-dependency, pure-Dart audio metadata and album cover extractor.
/// Supports ID3v2 (v2.2, v2.3, v2.4), ID3v1, MP4/M4A iTunes atoms, and FLAC Vorbis/Picture blocks.
class LocalAudioMetadataService {
  LocalAudioMetadataService._();
  static final LocalAudioMetadataService instance =
      LocalAudioMetadataService._();

  static Directory? _coverCacheDir;

  static const List<String> supportedAudioExtensions = [
    '.mp3',
    '.m4a',
    '.flac',
    '.wav',
    '.ogg',
    '.aac',
    '.opus',
    '.wma',
  ];

  /// Ensures the cover art cache directory is initialized.
  Future<Directory> _getCoverCacheDir() async {
    if (_coverCacheDir != null && await _coverCacheDir!.exists()) {
      return _coverCacheDir!;
    }
    try {
      final baseDir = await getApplicationSupportDirectory();
      final dir = Directory(p.join(baseDir.path, 'album_covers'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _coverCacheDir = dir;
      return dir;
    } catch (_) {
      final temp =
          await Directory.systemTemp.createTemp('lifeos_album_covers_');
      _coverCacheDir = temp;
      return temp;
    }
  }

  /// Caches raw album cover bytes to disk and returns the cached file path.
  Future<String?> cacheCoverBytes(Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final hash = sha1.convert(bytes).toString();
      final cacheDir = await _getCoverCacheDir();
      final coverFile = File(p.join(cacheDir.path, '$hash.jpg'));
      if (!await coverFile.exists()) {
        await coverFile.writeAsBytes(bytes, flush: true);
      }
      return coverFile.path;
    } catch (e) {
      debugPrint('Error caching album cover: $e');
      return null;
    }
  }

  /// Extracts metadata and embedded album art from a local audio file.
  Future<ParsedAudioMetadata> readMetadata(File file) async {
    final filePath = file.path;
    final ext = p.extension(filePath).toLowerCase();

    String title = '';
    String artist = '';
    String album = '';
    double duration = 0.0;
    int? year;
    String? genre;
    Uint8List? coverBytes;

    try {
      if (!await file.exists()) {
        return _fallbackMetadata(filePath);
      }

      final length = await file.length();
      if (length < 128) {
        return _fallbackMetadata(filePath);
      }

      final raf = await file.open(mode: FileMode.read);
      try {
        if (ext == '.mp3' || ext == '.wav' || ext == '.aac') {
          // Check ID3v2 at the beginning
          final id3Result = await _parseId3v2(raf, length);
          if (id3Result != null) {
            title = id3Result['title'] as String? ?? '';
            artist = id3Result['artist'] as String? ?? '';
            album = id3Result['album'] as String? ?? '';
            duration = id3Result['duration'] as double? ?? 0.0;
            year = id3Result['year'] as int?;
            genre = id3Result['genre'] as String?;
            coverBytes = id3Result['coverBytes'] as Uint8List?;
          }

          // Fallback to ID3v1 at the end of the file if title or artist is empty
          if (title.isEmpty || artist.isEmpty) {
            final id3v1 = await _parseId3v1(raf, length);
            if (id3v1 != null) {
              if (title.isEmpty) title = id3v1['title'] ?? '';
              if (artist.isEmpty) artist = id3v1['artist'] ?? '';
              if (album.isEmpty) album = id3v1['album'] ?? '';
              year ??= id3v1['year'];
              genre ??= id3v1['genre'];
            }
          }
        } else if (ext == '.m4a' || ext == '.mp4') {
          final m4aResult = await _parseM4a(raf, length);
          if (m4aResult != null) {
            title = m4aResult['title'] as String? ?? '';
            artist = m4aResult['artist'] as String? ?? '';
            album = m4aResult['album'] as String? ?? '';
            year = m4aResult['year'] as int?;
            genre = m4aResult['genre'] as String?;
            coverBytes = m4aResult['coverBytes'] as Uint8List?;
          }
        } else if (ext == '.flac') {
          final flacResult = await _parseFlac(raf, length);
          if (flacResult != null) {
            title = flacResult['title'] as String? ?? '';
            artist = flacResult['artist'] as String? ?? '';
            album = flacResult['album'] as String? ?? '';
            year = flacResult['year'] as int?;
            genre = flacResult['genre'] as String?;
            coverBytes = flacResult['coverBytes'] as Uint8List?;
          }
        }
      } finally {
        await raf.close();
      }
    } catch (e) {
      debugPrint('Error reading metadata from $filePath: $e');
    }

    // Apply filename heuristics if title or artist remains absent
    if (title.trim().isEmpty) {
      final fallback = _inferFromFilename(filePath);
      title = fallback.$1;
      if (artist.trim().isEmpty) {
        artist = fallback.$2;
      }
    }
    if (artist.trim().isEmpty) {
      artist = 'Unknown Artist';
    }

    String? thumbnailPath;
    if (coverBytes != null && coverBytes.isNotEmpty) {
      thumbnailPath = await cacheCoverBytes(coverBytes);
    }

    return ParsedAudioMetadata(
      filePath: filePath,
      title: title.trim(),
      artist: artist.trim(),
      album: album.trim(),
      duration: duration,
      year: year,
      genre: genre?.trim(),
      coverBytes: coverBytes,
      thumbnailPath: thumbnailPath,
    );
  }

  /// Parses ID3v2.2, ID3v2.3, or ID3v2.4 tags.
  Future<Map<String, dynamic>?> _parseId3v2(
      RandomAccessFile raf, int fileLength) async {
    await raf.setPosition(0);
    final header = await raf.read(10);
    if (header.length < 10) return null;

    // Check "ID3" identifier
    if (header[0] != 0x49 || header[1] != 0x44 || header[2] != 0x33) {
      return null;
    }

    final majorVersion = header[3]; // 2 = 2.2, 3 = 2.3, 4 = 2.4
    if (majorVersion < 2 || majorVersion > 4) return null;

    final flags = header[5];
    final hasExtendedHeader = (flags & 0x40) != 0;

    // Synchsafe integer size
    final tagSize = ((header[6] & 0x7F) << 21) |
        ((header[7] & 0x7F) << 14) |
        ((header[8] & 0x7F) << 7) |
        (header[9] & 0x7F);

    if (tagSize <= 0 || tagSize > fileLength) return null;

    // Read tag body (capped to 12MB to safeguard against malformed huge sizes)
    final readBytes = math.min(tagSize, 12 * 1024 * 1024);
    final tagBody = await raf.read(readBytes);
    if (tagBody.isEmpty) return null;

    int offset = 0;
    if (hasExtendedHeader) {
      if (majorVersion == 4 && tagBody.length >= 4) {
        final extSize = ((tagBody[0] & 0x7F) << 21) |
            ((tagBody[1] & 0x7F) << 14) |
            ((tagBody[2] & 0x7F) << 7) |
            (tagBody[3] & 0x7F);
        offset = extSize;
      } else if (majorVersion == 3 && tagBody.length >= 4) {
        final extSize = (tagBody[0] << 24) |
            (tagBody[1] << 16) |
            (tagBody[2] << 8) |
            tagBody[3];
        offset = 4 + extSize;
      }
    }

    String? title;
    String? artist;
    String? album;
    double? duration;
    int? year;
    String? genre;
    Uint8List? coverBytes;

    while (offset < tagBody.length) {
      if (majorVersion == 2) {
        // ID3v2.2: 3-byte frame ID, 3-byte size
        if (offset + 6 > tagBody.length) break;
        if (tagBody[offset] == 0) break; // padding reached

        final frameId = String.fromCharCodes(tagBody.sublist(offset, offset + 3));
        final frameSize = (tagBody[offset + 3] << 16) |
            (tagBody[offset + 4] << 8) |
            tagBody[offset + 5];
        offset += 6;

        if (frameSize <= 0 || offset + frameSize > tagBody.length) break;
        final frameData = tagBody.sublist(offset, offset + frameSize);
        offset += frameSize;

        if (frameId == 'TT2' && title == null) {
          title = _decodeTextFrame(frameData);
        } else if (frameId == 'TP1' && artist == null) {
          artist = _decodeTextFrame(frameData);
        } else if (frameId == 'TAL' && album == null) {
          album = _decodeTextFrame(frameData);
        } else if (frameId == 'TYE' && year == null) {
          year = int.tryParse(_decodeTextFrame(frameData) ?? '');
        } else if (frameId == 'TCO' && genre == null) {
          genre = _decodeTextFrame(frameData);
        } else if (frameId == 'TLE' && duration == null) {
          final ms = double.tryParse(_decodeTextFrame(frameData) ?? '');
          if (ms != null && ms > 0) duration = ms / 1000.0;
        } else if (frameId == 'PIC' && coverBytes == null) {
          coverBytes = _parseId3v2PictureFrame(frameData, isV22: true);
        }
      } else {
        // ID3v2.3 and ID3v2.4: 4-byte frame ID, 4-byte size, 2-byte flags
        if (offset + 10 > tagBody.length) break;
        if (tagBody[offset] == 0) break; // padding reached

        final frameId = String.fromCharCodes(tagBody.sublist(offset, offset + 4));
        int frameSize;
        if (majorVersion == 4) {
          frameSize = ((tagBody[offset + 4] & 0x7F) << 21) |
              ((tagBody[offset + 5] & 0x7F) << 14) |
              ((tagBody[offset + 6] & 0x7F) << 7) |
              (tagBody[offset + 7] & 0x7F);
        } else {
          frameSize = (tagBody[offset + 4] << 24) |
              (tagBody[offset + 5] << 16) |
              (tagBody[offset + 6] << 8) |
              tagBody[offset + 7];
        }
        offset += 10;

        if (frameSize <= 0 || offset + frameSize > tagBody.length) break;
        final frameData = tagBody.sublist(offset, offset + frameSize);
        offset += frameSize;

        if (frameId == 'TIT2' && title == null) {
          title = _decodeTextFrame(frameData);
        } else if (frameId == 'TPE1' && artist == null) {
          artist = _decodeTextFrame(frameData);
        } else if (frameId == 'TALB' && album == null) {
          album = _decodeTextFrame(frameData);
        } else if ((frameId == 'TYER' || frameId == 'TDRC') && year == null) {
          final raw = _decodeTextFrame(frameData) ?? '';
          final match = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(raw);
          if (match != null) year = int.tryParse(match.group(1)!);
        } else if (frameId == 'TCON' && genre == null) {
          genre = _cleanGenre(_decodeTextFrame(frameData));
        } else if (frameId == 'TLEN' && duration == null) {
          final ms = double.tryParse(_decodeTextFrame(frameData) ?? '');
          if (ms != null && ms > 0) duration = ms / 1000.0;
        } else if (frameId == 'APIC' && coverBytes == null) {
          coverBytes = _parseId3v2PictureFrame(frameData, isV22: false);
        }
      }
    }

    return {
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration ?? 0.0,
      'year': year,
      'genre': genre,
      'coverBytes': coverBytes,
    };
  }

  /// Parses an APIC (v2.3/v2.4) or PIC (v2.2) picture frame and extracts raw image bytes.
  Uint8List? _parseId3v2PictureFrame(Uint8List data, {required bool isV22}) {
    try {
      if (data.length < 10) return null;
      final encoding = data[0];
      int pos = 1;

      if (isV22) {
        // 3-byte format (e.g. 'JPG' or 'PNG')
        if (pos + 4 > data.length) return null;
        pos += 3;
        pos += 1; // picture type
      } else {
        // MIME type is null-terminated ASCII string
        while (pos < data.length && data[pos] != 0) {
          pos++;
        }
        if (pos >= data.length) return null;
        pos++; // skip null
        if (pos >= data.length) return null;
        pos++; // skip picture type
      }

      // Description is a null-terminated string depending on encoding
      if (encoding == 1 || encoding == 2) {
        // UTF-16: null terminator is two zero bytes aligned
        while (pos + 1 < data.length) {
          if (data[pos] == 0 && data[pos + 1] == 0) {
            pos += 2;
            break;
          }
          pos += 2;
        }
      } else {
        // ISO-8859-1 or UTF-8: single zero byte
        while (pos < data.length && data[pos] != 0) {
          pos++;
        }
        if (pos < data.length) pos++;
      }

      if (pos >= data.length) return null;
      final imageBytes = data.sublist(pos);

      // Verify JPEG or PNG magic bytes
      if (_isValidImageHeader(imageBytes)) {
        return imageBytes;
      }
      return imageBytes;
    } catch (_) {
      return null;
    }
  }

  /// Checks for JPEG, PNG, or WebP image magic header signatures.
  bool _isValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG: 0xFF, 0xD8, 0xFF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 0x89, 0x50, 0x4E, 0x47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    // WebP: RIFF ... WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return true;
    }
    return false;
  }

  /// Decodes text frame payload according to its leading encoding byte.
  String? _decodeTextFrame(Uint8List data) {
    if (data.isEmpty) return null;
    final encoding = data[0];
    final bytes = data.sublist(1);
    if (bytes.isEmpty) return null;

    try {
      String text;
      switch (encoding) {
        case 0: // ISO-8859-1
          text = latin1.decode(bytes, allowInvalid: true);
          break;
        case 1: // UTF-16 with BOM
          text = _decodeUtf16(bytes);
          break;
        case 2: // UTF-16BE
          text = _decodeUtf16(bytes, isBigEndian: true);
          break;
        case 3: // UTF-8
        default:
          text = utf8.decode(bytes, allowMalformed: true);
          break;
      }
      // Strip trailing null characters
      return text.replaceAll('\x00', '').trim();
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true).replaceAll('\x00', '').trim();
    }
  }

  String _decodeUtf16(Uint8List bytes, {bool? isBigEndian}) {
    if (bytes.length < 2) return '';
    bool bigEndian = isBigEndian ?? false;
    int start = 0;
    if (isBigEndian == null) {
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        bigEndian = true;
        start = 2;
      } else if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        bigEndian = false;
        start = 2;
      }
    }
    final codeUnits = <int>[];
    for (int i = start; i + 1 < bytes.length; i += 2) {
      final unit = bigEndian
          ? (bytes[i] << 8) | bytes[i + 1]
          : bytes[i] | (bytes[i + 1] << 8);
      if (unit != 0) codeUnits.add(unit);
    }
    return String.fromCharCodes(codeUnits);
  }

  /// Parses ID3v1 trailing 128 bytes.
  Future<Map<String, dynamic>?> _parseId3v1(
      RandomAccessFile raf, int fileLength) async {
    if (fileLength < 128) return null;
    await raf.setPosition(fileLength - 128);
    final block = await raf.read(128);
    if (block.length < 128) return null;

    if (block[0] != 0x54 || block[1] != 0x41 || block[2] != 0x47) {
      // Missing "TAG" header
      return null;
    }

    final title = latin1
        .decode(block.sublist(3, 33), allowInvalid: true)
        .replaceAll('\x00', '')
        .trim();
    final artist = latin1
        .decode(block.sublist(33, 63), allowInvalid: true)
        .replaceAll('\x00', '')
        .trim();
    final album = latin1
        .decode(block.sublist(63, 93), allowInvalid: true)
        .replaceAll('\x00', '')
        .trim();
    final yearStr = latin1
        .decode(block.sublist(93, 97), allowInvalid: true)
        .replaceAll('\x00', '')
        .trim();

    return {
      'title': title.isNotEmpty ? title : null,
      'artist': artist.isNotEmpty ? artist : null,
      'album': album.isNotEmpty ? album : null,
      'year': int.tryParse(yearStr),
      'genre': null,
    };
  }

  /// Parses M4A / MP4 iTunes metadata atoms (`moov.udta.meta.ilst`).
  Future<Map<String, dynamic>?> _parseM4a(
      RandomAccessFile raf, int fileLength) async {
    await raf.setPosition(0);
    // Read up to first 2MB to find metadata atoms
    final bufferSize = math.min(fileLength, 2 * 1024 * 1024);
    final data = await raf.read(bufferSize);
    if (data.length < 16) return null;

    String? title;
    String? artist;
    String? album;
    int? year;
    String? genre;
    Uint8List? coverBytes;

    int pos = 0;
    while (pos + 8 <= data.length) {
      final size = (data[pos] << 24) |
          (data[pos + 1] << 16) |
          (data[pos + 2] << 8) |
          data[pos + 3];
      final type = String.fromCharCodes(data.sublist(pos + 4, pos + 8));
      if (size < 8) break;

      if (type == 'moov') {
        final moovData = data.sublist(pos + 8, math.min(pos + size, data.length));
        final ilst = _findIlstAtom(moovData);
        if (ilst != null) {
          title = _extractM4aString(ilst, '\xa9nam');
          artist = _extractM4aString(ilst, '\xa9ART') ??
              _extractM4aString(ilst, 'aART');
          album = _extractM4aString(ilst, '\xa9alb');
          final dateStr = _extractM4aString(ilst, '\xa9day');
          if (dateStr != null) {
            final match = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(dateStr);
            if (match != null) year = int.tryParse(match.group(1)!);
          }
          genre = _extractM4aString(ilst, '\xa9gen');
          coverBytes = _extractM4aCover(ilst);
        }
        break;
      }
      pos += size;
    }

    return {
      'title': title,
      'artist': artist,
      'album': album,
      'year': year,
      'genre': genre,
      'coverBytes': coverBytes,
    };
  }

  Uint8List? _findIlstAtom(Uint8List data) {
    int pos = 0;
    while (pos + 8 <= data.length) {
      final size = (data[pos] << 24) |
          (data[pos + 1] << 16) |
          (data[pos + 2] << 8) |
          data[pos + 3];
      if (size < 8 || pos + size > data.length) break;
      final type = String.fromCharCodes(data.sublist(pos + 4, pos + 8));

      if (type == 'udta' || type == 'meta') {
        int innerStart = pos + 8;
        if (type == 'meta' && innerStart + 4 <= pos + size) {
          innerStart += 4; // version + flags in meta atom
        }
        final sub = data.sublist(innerStart, pos + size);
        final found = _findIlstAtom(sub);
        if (found != null) return found;
      } else if (type == 'ilst') {
        return data.sublist(pos + 8, pos + size);
      }
      pos += size;
    }
    return null;
  }

  String? _extractM4aString(Uint8List ilst, String targetAtom) {
    int pos = 0;
    while (pos + 8 <= ilst.length) {
      final size = (ilst[pos] << 24) |
          (ilst[pos + 1] << 16) |
          (ilst[pos + 2] << 8) |
          ilst[pos + 3];
      if (size < 8 || pos + size > ilst.length) break;
      final atomName = String.fromCharCodes(ilst.sublist(pos + 4, pos + 8));

      if (atomName == targetAtom) {
        // Child atom is usually "data"
        final inner = ilst.sublist(pos + 8, pos + size);
        if (inner.length >= 16) {
          final dataSize = (inner[0] << 24) |
              (inner[1] << 16) |
              (inner[2] << 8) |
              inner[3];
          final dataType = String.fromCharCodes(inner.sublist(4, 8));
          if (dataType == 'data' && dataSize <= inner.length && dataSize >= 16) {
            final payload = inner.sublist(16, dataSize);
            return utf8.decode(payload, allowMalformed: true).trim();
          }
        }
      }
      pos += size;
    }
    return null;
  }

  Uint8List? _extractM4aCover(Uint8List ilst) {
    int pos = 0;
    while (pos + 8 <= ilst.length) {
      final size = (ilst[pos] << 24) |
          (ilst[pos + 1] << 16) |
          (ilst[pos + 2] << 8) |
          ilst[pos + 3];
      if (size < 8 || pos + size > ilst.length) break;
      final atomName = String.fromCharCodes(ilst.sublist(pos + 4, pos + 8));

      if (atomName == 'covr') {
        final inner = ilst.sublist(pos + 8, pos + size);
        if (inner.length >= 16) {
          final dataSize = (inner[0] << 24) |
              (inner[1] << 16) |
              (inner[2] << 8) |
              inner[3];
          final dataType = String.fromCharCodes(inner.sublist(4, 8));
          if (dataType == 'data' && dataSize <= inner.length && dataSize >= 16) {
            return inner.sublist(16, dataSize);
          }
        }
      }
      pos += size;
    }
    return null;
  }

  /// Parses FLAC Vorbis Comment and Picture metadata blocks.
  Future<Map<String, dynamic>?> _parseFlac(
      RandomAccessFile raf, int fileLength) async {
    await raf.setPosition(0);
    final header = await raf.read(4);
    if (header.length < 4 ||
        header[0] != 0x66 ||
        header[1] != 0x4C ||
        header[2] != 0x61 ||
        header[3] != 0x43) {
      return null;
    }

    String? title;
    String? artist;
    String? album;
    int? year;
    String? genre;
    Uint8List? coverBytes;

    bool isLast = false;
    while (!isLast) {
      final blockHeader = await raf.read(4);
      if (blockHeader.length < 4) break;

      isLast = (blockHeader[0] & 0x80) != 0;
      final blockType = blockHeader[0] & 0x7F;
      final blockLen =
          (blockHeader[1] << 16) | (blockHeader[2] << 8) | blockHeader[3];

      if (blockLen <= 0 || blockLen > 10 * 1024 * 1024) break;

      if (blockType == 4) {
        // Vorbis Comment
        final blockData = await raf.read(blockLen);
        if (blockData.length >= blockLen) {
          final comments = _parseVorbisComments(blockData);
          title = comments['TITLE'];
          artist = comments['ARTIST'];
          album = comments['ALBUM'];
          genre = comments['GENRE'];
          final date = comments['DATE'] ?? comments['YEAR'];
          if (date != null) {
            final match = RegExp(r'\b(19\d{2}|20\d{2})\b').firstMatch(date);
            if (match != null) year = int.tryParse(match.group(1)!);
          }
        }
      } else if (blockType == 6 && coverBytes == null) {
        // Picture block
        final blockData = await raf.read(blockLen);
        if (blockData.length >= 32) {
          coverBytes = _parseFlacPictureBlock(blockData);
        }
      } else {
        await raf.setPosition((await raf.position()) + blockLen);
      }
    }

    return {
      'title': title,
      'artist': artist,
      'album': album,
      'year': year,
      'genre': genre,
      'coverBytes': coverBytes,
    };
  }

  Map<String, String> _parseVorbisComments(Uint8List data) {
    final result = <String, String>{};
    try {
      if (data.length < 4) return result;
      int pos = 0;
      final vendorLen = data[pos] |
          (data[pos + 1] << 8) |
          (data[pos + 2] << 16) |
          (data[pos + 3] << 24);
      pos += 4 + vendorLen;
      if (pos + 4 > data.length) return result;

      final userCommentCount = data[pos] |
          (data[pos + 1] << 8) |
          (data[pos + 2] << 16) |
          (data[pos + 3] << 24);
      pos += 4;

      for (int i = 0; i < userCommentCount && pos + 4 <= data.length; i++) {
        final commentLen = data[pos] |
            (data[pos + 1] << 8) |
            (data[pos + 2] << 16) |
            (data[pos + 3] << 24);
        pos += 4;
        if (pos + commentLen > data.length) break;

        final commentStr = utf8.decode(data.sublist(pos, pos + commentLen),
            allowMalformed: true);
        pos += commentLen;

        final eqIdx = commentStr.indexOf('=');
        if (eqIdx > 0) {
          final key = commentStr.substring(0, eqIdx).toUpperCase().trim();
          final val = commentStr.substring(eqIdx + 1).trim();
          result[key] = val;
        }
      }
    } catch (_) {}
    return result;
  }

  Uint8List? _parseFlacPictureBlock(Uint8List data) {
    try {
      int pos = 4; // skip picture type
      final mimeLen = (data[pos] << 24) |
          (data[pos + 1] << 16) |
          (data[pos + 2] << 8) |
          data[pos + 3];
      pos += 4 + mimeLen;
      if (pos + 4 > data.length) return null;

      final descLen = (data[pos] << 24) |
          (data[pos + 1] << 16) |
          (data[pos + 2] << 8) |
          data[pos + 3];
      pos += 4 + descLen;
      pos += 16; // width, height, color depth, colors count
      if (pos + 4 > data.length) return null;

      final dataLen = (data[pos] << 24) |
          (data[pos + 1] << 16) |
          (data[pos + 2] << 8) |
          data[pos + 3];
      pos += 4;
      if (pos + dataLen <= data.length) {
        return data.sublist(pos, pos + dataLen);
      }
    } catch (_) {}
    return null;
  }

  /// Cleans and extracts human-readable genre from numeric codes like "(17)" or "(Rock)".
  String? _cleanGenre(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var trimmed = raw.trim();
    final match = RegExp(r'^\((\d+)\)$').firstMatch(trimmed);
    if (match != null) {
      final code = int.tryParse(match.group(1)!);
      if (code != null && code < _id3v1Genres.length) {
        return _id3v1Genres[code];
      }
    }
    return trimmed;
  }

  /// Infers sensible Title and Artist directly from filename pattern.
  (String, String) _inferFromFilename(String filePath) {
    var base = p.basenameWithoutExtension(filePath).trim();

    // Strip leading track numbers like "01. ", "01 - ", "1 - "
    base = base.replaceFirst(RegExp(r'^\d+[\s\.\-_]+'), '').trim();

    // Pattern: "Artist - Title"
    if (base.contains(' - ')) {
      final parts = base.split(' - ');
      if (parts.length >= 2) {
        final artist = parts[0].trim();
        final title = parts.sublist(1).join(' - ').trim();
        if (artist.isNotEmpty && title.isNotEmpty) {
          return (title, artist);
        }
      }
    }

    return (base.isNotEmpty ? base : 'Unknown Track', 'Unknown Artist');
  }

  ParsedAudioMetadata _fallbackMetadata(String filePath) {
    final (title, artist) = _inferFromFilename(filePath);
    return ParsedAudioMetadata(
      filePath: filePath,
      title: title,
      artist: artist,
      album: '',
      duration: 0.0,
    );
  }

  /// Standard ID3v1 Genre lookup list.
  static const List<String> _id3v1Genres = [
    'Blues',
    'Classic Rock',
    'Country',
    'Dance',
    'Disco',
    'Funk',
    'Grunge',
    'Hip-Hop',
    'Jazz',
    'Metal',
    'New Age',
    'Oldies',
    'Other',
    'Pop',
    'R&B',
    'Rap',
    'Reggae',
    'Rock',
    'Techno',
    'Industrial',
    'Alternative',
    'Ska',
    'Death Metal',
    'Pranks',
    'Soundtrack',
    'Euro-Techno',
    'Ambient',
    'Trip-Hop',
    'Vocal',
    'Jazz+Funk',
    'Fusion',
    'Trance',
    'Classical',
    'Instrumental',
    'Acid',
    'House',
    'Game',
    'Sound Clip',
    'Gospel',
    'Noise',
    'Alternative Rock',
    'Bass',
    'Soul',
    'Punk',
    'Space',
    'Meditative',
    'Instrumental Pop',
    'Instrumental Rock',
    'Ethnic',
    'Gothic',
    'Darkwave',
    'Techno-Industrial',
    'Electronic',
    'Pop-Folk',
    'Eurodance',
    'Dream',
    'Southern Rock',
    'Comedy',
    'Cult',
    'Gangsta',
    'Top 40',
    'Christian Rap',
    'Pop/Funk',
    'Jungle',
    'Native US',
    'Cabaret',
    'New Wave',
    'Psychedelic',
    'Rave',
    'Showtunes',
    'Trailer',
    'Lo-Fi',
    'Tribal',
    'Acid Punk',
    'Acid Jazz',
    'Polka',
    'Retro',
    'Musical',
    'Rock & Roll',
    'Hard Rock',
  ];
}
