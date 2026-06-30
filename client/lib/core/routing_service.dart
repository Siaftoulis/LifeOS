import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RoutingService {
  static final RoutingService _instance = RoutingService._internal();
  factory RoutingService() => _instance;
  RoutingService._internal();

  /// Fetches a driving/walking route from OSRM public API.
  Future<RouteResult?> getRoute(LatLng start, LatLng destination, {String profile = 'driving'}) async {
    final startStr = '${start.longitude},${start.latitude}';
    final destStr = '${destination.longitude},${destination.latitude}';
    final url = 'http://router.project-osrm.org/route/v1/$profile/$startStr;$destStr?geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final routeData = data['routes'][0];
          final geometry = routeData['geometry'];
          final coordinates = geometry['coordinates'] as List;
          final List<LatLng> points = coordinates.map((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
          
          final distanceMeters = (routeData['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds = (routeData['duration'] as num?)?.toDouble() ?? 0.0;

          return RouteResult(
            points: points,
            distanceKm: distanceMeters / 1000.0,
            durationMinutes: durationSeconds / 60.0,
          );
        }
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    return null;
  }
}
