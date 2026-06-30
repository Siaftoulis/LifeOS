import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingSearchResult {
  final String name;
  final String description;
  final LatLng coordinate;

  GeocodingSearchResult({
    required this.name,
    required this.description,
    required this.coordinate,
  });
}

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._internal();
  factory GeocodingService() => _instance;
  GeocodingService._internal();

  /// Searches for places using Photon autocomplete API.
  Future<List<GeocodingSearchResult>> search(String query, {LatLng? biasLocation}) async {
    if (query.trim().isEmpty) return [];

    var url = 'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=5';
    if (biasLocation != null) {
      url += '&lat=${biasLocation.latitude}&lon=${biasLocation.longitude}';
    }

    print('Geocoding URL: $url');

    try {
      final response = await http.get(Uri.parse(url));
      print('Geocoding Status Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final bodyStr = utf8.decode(response.bodyBytes);
        print('Geocoding Response Length: ${bodyStr.length}');
        final data = json.decode(bodyStr);
        final features = data['features'] as List?;
        print('Geocoding Features Count: ${features?.length ?? 0}');
        if (features != null) {
          final List<GeocodingSearchResult> results = [];
          for (final f in features) {
            final geom = f['geometry'];
            final coords = geom['coordinates'] as List;
            final lng = coords[0] as double;
            final lat = coords[1] as double;

            final props = f['properties'] ?? {};
            final name = props['name']?.toString() ?? '';
            
            // Build a descriptive label
            final List<String> details = [];
            if (props['street'] != null) details.add(props['street'].toString());
            if (props['housenumber'] != null) details.add(props['housenumber'].toString());
            if (props['city'] != null) details.add(props['city'].toString());
            if (props['country'] != null) details.add(props['country'].toString());

            print('Found suggestion: $name (${details.join(', ')}) at [$lat, $lng]');

            results.add(GeocodingSearchResult(
              name: name,
              description: details.join(', '),
              coordinate: LatLng(lat, lng),
            ));
          }
          return results;
        }
      } else {
        print('Geocoding HTTP Error Body: ${response.body}');
      }
    } catch (e) {
      print('Geocoding error: $e');
    }
    return [];
  }
}
