import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/everforest_colors.dart';

import '../../../database/database.dart';

import 'dart:math' as math;

class OsmMapWidget extends StatefulWidget {
  final List<Map<String, dynamic>> liveLocations;
  final bool isDrawingMode;
  final MapController mapController;
  final LatLng? myLocation;
  final List<Geofence> geofences;
  final Function(LatLng)? onMapTap;

  const OsmMapWidget({
    super.key,
    required this.liveLocations,
    this.isDrawingMode = false,
    required this.mapController,
    this.myLocation,
    this.geofences = const [],
    this.onMapTap,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  double _rotation = 0.0;

  @override
  Widget build(BuildContext context) {
    // Default to Athens if no live locations
    final defaultCenter = const LatLng(37.9838, 23.7275);
    final center = widget.liveLocations.isNotEmpty
        ? LatLng(widget.liveLocations.first['latitude'] as double, widget.liveLocations.first['longitude'] as double)
        : defaultCenter;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              keepAlive: true,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (position, hasGesture) {
                if (mounted) {
                  setState(() => _rotation = widget.mapController.camera.rotation);
                }
              },
              onTap: (tapPosition, point) {
                if (widget.isDrawingMode && widget.onMapTap != null) {
                  widget.onMapTap!(point);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.lifeos.app',
              ),
              if (widget.geofences.isNotEmpty)
                CircleLayer(
                  circles: widget.geofences
                      .where((g) => g.isActive == 1)
                      .map((g) => CircleMarker(
                            point: LatLng(g.latitude, g.longitude),
                            radius: g.radius,
                            useRadiusInMeter: true,
                            color: EverforestColors.green.withOpacity(0.15),
                            borderColor: EverforestColors.green,
                            borderStrokeWidth: 2,
                          ))
                      .toList(),
                ),
              if (widget.myLocation != null) ...[
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: widget.myLocation!,
                      radius: 40,
                      useRadiusInMeter: false,
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue.withOpacity(0.4),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.myLocation!,
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              MarkerLayer(
                markers: widget.liveLocations.where((loc) => loc['device_id'] != 'flutter_dashboard').map((loc) {
                  return Marker(
                    point: LatLng(loc['latitude'] as double, loc['longitude'] as double),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.person_pin_circle,
                      color: EverforestColors.red,
                      size: 40,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: _rotation != 0.0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: EverforestColors.bg1.withOpacity(0.9),
                onPressed: () {
                  widget.mapController.rotate(0.0);
                },
                child: Transform.rotate(
                  angle: -_rotation * math.pi / 180,
                  child: const Icon(Icons.navigation, color: EverforestColors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
