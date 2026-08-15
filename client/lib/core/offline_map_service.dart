import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

/// Persistent on-disk tile cache + region pre-fetch for offline map viewing.
///
/// flutter_map's NetworkTileProvider already reads/writes this cache on every
/// tile load, so zoom/pan never re-downloads tiles that are still fresh, and
/// prefetched regions render offline.
class OfflineMapService {
  OfflineMapService._();

  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _freshAge = Duration(days: 90);
  static const _maxTilesPerZoom = 2500;

  static BuiltInMapCachingProvider? _provider;

  /// Call once at startup, BEFORE any map is built, so the singleton cache is
  /// configured with a persistent directory and a long freshness age.
  static Future<void> init() async {
    final supportDir = await getApplicationSupportDirectory();
    final cacheDir = '${supportDir.path}/map_tiles';
    _provider = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: cacheDir,
      maxCacheSize: 500 * 1024 * 1024, // 500 MB
      overrideFreshAge: _freshAge,
    );
  }

  static BuiltInMapCachingProvider get _cache =>
      _provider ?? BuiltInMapCachingProvider.getOrCreateInstance();

  /// Downloads the tiles covering [points] (e.g. photo GPS metadata) for
  /// zoom levels [minZoom]..[maxZoom]. Tiles already cached & fresh are
  /// skipped. Returns number of tiles downloaded. Calls [onProgress] with
  /// (done, total) as it goes.
  static Future<int> prefetchRegion(
    List<LatLng> points, {
    int minZoom = 10,
    int maxZoom = 17,
    void Function(int done, int total)? onProgress,
  }) async {
    if (points.isEmpty) return 0;

    final bounds = _boundingBox(points);
    final provider = _cache;
    final client = http.Client();
    var downloaded = 0;
    var total = 0;

    try {
      for (var z = minZoom; z <= maxZoom; z++) {
        final (xMin, yMin, xMax, yMax) = _tileRange(bounds, z);
        final zoomTiles = (xMax - xMin + 1) * (yMax - yMin + 1);
        if (zoomTiles > _maxTilesPerZoom) continue; // region too large, skip zoom
        total += zoomTiles;
      }

      for (var z = minZoom; z <= maxZoom; z++) {
        final (xMin, yMin, xMax, yMax) = _tileRange(bounds, z);
        final zoomTiles = (xMax - xMin + 1) * (yMax - yMin + 1);
        if (zoomTiles > _maxTilesPerZoom) continue;

        for (var x = xMin; x <= xMax; x++) {
          for (var y = yMin; y <= yMax; y++) {
            final url = _tileUrl
                .replaceAll('{z}', '$z')
                .replaceAll('{x}', '$x')
                .replaceAll('{y}', '$y');
            try {
              final cached = await provider.getTile(url);
              if (cached != null && !cached.metadata.isStale) continue;

              final resp = await client.get(
                Uri.parse(url),
                headers: const {'User-Agent': 'lifeos-client/1.0'},
              );
              if (resp.statusCode == 200) {
                await provider.putTile(
                  url: url,
                  metadata: CachedMapTileMetadata(
                    staleAt: DateTime.now().add(_freshAge),
                    lastModified: null,
                    etag: null,
                  ),
                  bytes: resp.bodyBytes,
                );
                downloaded++;
              }
            } catch (_) {
              // Skip tiles that fail (offline, server hiccup, etc.)
            }
            onProgress?.call(downloaded, total);
          }
        }
      }
    } finally {
      client.close();
    }
    return downloaded;
  }

  static (double, double, double, double) _boundingBox(List<LatLng> points) {
    var minLat = points.first.latitude, maxLat = minLat;
    var minLng = points.first.longitude, maxLng = minLng;
    for (final p in points.skip(1)) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    // ~5km padding so the map can be panned a bit around the photos
    final padLat = math.max(0.05, (maxLat - minLat) * 0.25);
    final padLng = math.max(0.05, (maxLng - minLng) * 0.25);
    return (
      math.max(-85.0, minLat - padLat),
      math.min(85.0, maxLat + padLat),
      math.max(-180.0, minLng - padLng),
      math.min(180.0, maxLng + padLng),
    );
  }

  static (int, int, int, int) _tileRange(
    (double, double, double, double) bounds,
    int zoom,
  ) {
    final n = math.pow(2, zoom).toDouble();
    final (minLat, maxLat, minLng, maxLng) = bounds;
    int xOf(double lng) => ((lng + 180) / 360 * n).floor();
    int yOf(double lat) {
      final r = lat * math.pi / 180;
      return ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n)
          .floor();
    }

    final xMin = math.max(0, xOf(minLng));
    final xMax = math.min((n - 1).toInt(), xOf(maxLng));
    final yMin = math.max(0, yOf(maxLat));
    final yMax = math.min((n - 1).toInt(), yOf(minLat));
    return (xMin, yMin, xMax, yMax);
  }
}
