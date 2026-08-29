import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import '../../../database/database.dart';

class MapsEmbedPreview extends StatelessWidget {
  const MapsEmbedPreview({super.key, this.ref});

  /// Single-pin embed reference (geofence id from the daemon).
  final String? ref;

  @override
  Widget build(BuildContext context) {
    if (ref != null && ref!.isNotEmpty) {
      return _SinglePinEmbed(ref: ref!);
    }
    return StreamBuilder<List<Geofence>>(
      stream: AppDatabase.instance.mapsDao.watchAllGeofences(),
      builder: (context, snapshot) {
        final pins = (snapshot.data ?? const <Geofence>[])
            .where((g) => g.isActive == 1)
            .toList();
        if (pins.isEmpty) {
          return const Center(
            child: Text(
              'No places pinned yet — tap to open the map',
              style: TextStyle(color: EverforestColors.grey),
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: _PinsPainter(
                  pins: pins
                      .map((g) => (lat: g.latitude, lng: g.longitude, name: g.name))
                      .toList(),
                ),
              ),
            ),
            Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pins.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: EverforestColors.green),
                      const SizedBox(width: 4),
                      Text(
                        pins[index].name,
                        style: const TextStyle(
                          color: EverforestColors.fg,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PinsPainter extends CustomPainter {
  _PinsPainter({required this.pins});

  final List<({double lat, double lng, String name})> pins;

  @override
  void paint(Canvas canvas, Size size) {
    var minLat = pins.first.lat;
    var maxLat = pins.first.lat;
    var minLng = pins.first.lng;
    var maxLng = pins.first.lng;
    for (final p in pins) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final spanLat = math.max(maxLat - minLat, 0.0001);
    final spanLng = math.max(maxLng - minLng, 0.0001);
    const pad = 20.0;

    Offset project(double lat, double lng) {
      final x = pad + (lng - minLng) / spanLng * (size.width - pad * 2);
      final y = size.height -
          pad -
          (lat - minLat) / spanLat * (size.height - pad * 2);
      return Offset(x, y);
    }

    final paint = Paint()
      ..color = const Color(0xFF2E383C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = 1; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          size.width / 3 * i,
          0,
          size.width / 3 * i,
          size.height,
        ).deflate(0.001),
        paint,
      );
    }

    for (final p in pins) {
      final pos = project(p.lat, p.lng);
      canvas.drawCircle(pos, 5, Paint()..color = EverforestColors.green);
      canvas.drawCircle(
        pos,
        8,
        Paint()..color = EverforestColors.green.withValues(alpha: 0.3),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: p.name,
          style: const TextStyle(
            color: EverforestColors.fg,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width / 2);
      tp.paint(canvas, pos + const Offset(10, -4));
    }
  }

  @override
  bool shouldRepaint(_PinsPainter oldDelegate) =>
      oldDelegate.pins != pins;
}

class _SinglePinEmbed extends StatelessWidget {
  const _SinglePinEmbed({required this.ref});

  final String ref;

  @override
  Widget build(BuildContext context) {
    return _SinglePinMap(ref: ref);
  }
}

class _SinglePinMap extends StatefulWidget {
  const _SinglePinMap({required this.ref});

  final String ref;

  @override
  State<_SinglePinMap> createState() => _SinglePinMapState();
}

class _SinglePinMapState extends State<_SinglePinMap> {
  Map<String, dynamic>? _pin;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance
          .getDaemon('/api/v1/radar/geofences/${widget.ref}');
      if (mounted) {
        setState(() => _pin = res is Map ? Map<String, dynamic>.from(res) : null);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Text(
          'Pin not found — tap to open the map',
          style: TextStyle(color: EverforestColors.grey),
        ),
      );
    }
    final pin = _pin;
    if (pin == null) {
      return const Center(
        child: CircularProgressIndicator(color: EverforestColors.green),
      );
    }
    final lat = pin['lat'] is num ? (pin['lat'] as num).toDouble() : 0.0;
    final lng = pin['lon'] is num ? (pin['lon'] as num).toDouble() : 0.0;
    final name = pin['name'] as String? ?? widget.ref;
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _PinsPainter(pins: [(lat: lat, lng: lng, name: name)]),
          ),
        ),
        Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: const BoxDecoration(color: EverforestColors.bg2),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: EverforestColors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$name — ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                ),
              ),
              Text(
                pin['radius'] is num
                    ? '${(pin['radius'] as num).toInt()} m radius'
                    : '',
                style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
