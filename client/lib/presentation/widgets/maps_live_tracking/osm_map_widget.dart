import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/everforest_colors.dart';

class OsmMapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> liveLocations;
  final bool isDrawingMode;
  final MapController mapController;
  final LatLng? myLocation;

  const OsmMapWidget({
    super.key, 
    required this.liveLocations,
    this.isDrawingMode = false,
    required this.mapController,
    this.myLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Default to Athens if no live locations
    final defaultCenter = const LatLng(37.9838, 23.7275);
    final center = liveLocations.isNotEmpty
        ? LatLng(liveLocations.first['latitude'] as double, liveLocations.first['longitude'] as double)
        : defaultCenter;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 13.0,
          keepAlive: true,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.lifeos.app',
          ),
          if (isDrawingMode)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: [
                    LatLng(center.latitude - 0.005, center.longitude - 0.005),
                    LatLng(center.latitude - 0.005, center.longitude + 0.005),
                    LatLng(center.latitude + 0.005, center.longitude + 0.005),
                    LatLng(center.latitude + 0.005, center.longitude - 0.005),
                  ],
                  color: EverforestColors.green.withOpacity(0.3),
                  borderColor: EverforestColors.green,
                  borderStrokeWidth: 2,
                )
              ],
            ),
          if (myLocation != null) ...[
            CircleLayer(
              circles: [
                CircleMarker(
                  point: myLocation!,
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
                  point: myLocation!,
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
            markers: liveLocations.where((loc) => loc['device_id'] != 'flutter_dashboard').map((loc) {
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
    );
  }
}
