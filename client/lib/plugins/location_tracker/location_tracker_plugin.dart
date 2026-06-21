import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/base_plugin.dart';
import '../../api_client.dart';

class LocationTrackerPlugin implements BasePlugin {
  @override String get pluginId => 'PLUG-LOCATION';
  @override String get title => 'Location Tracker';
  @override IconData get icon => Icons.my_location;

  StreamSubscription<Position>? _positionStream;

  @override 
  Future<void> initialize(dynamic db, ApiClient api) async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position position) {
          api.postDaemon('/api/v1/radar/report', {
            'device_id': 'flutter_dashboard',
            'latitude': position.latitude,
            'longitude': position.longitude,
            'velocity': position.speed,
            'altitude': position.altitude,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }).catchError((_) {});
        }
      );
    } catch (e) {
      debugPrint("Failed to initialize location plugin: $e");
    }
  }

  @override 
  Widget buildView(BuildContext context) {
    return const Center(child: Text('Location Service Active', style: TextStyle(color: Colors.white)));
  }
}
