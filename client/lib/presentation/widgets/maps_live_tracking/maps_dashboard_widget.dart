import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../api_client.dart';
import '../../../database/database.dart';
import '../../../database/maps_dao.dart';
import '../../../theme/everforest_colors.dart';
import 'geofence_drawer_overlay.dart';
import 'navigation_overlay.dart';
import 'maps_dashboard_header.dart';
import 'maps_report_banner.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'osm_map_widget.dart';

class MapsDashboardWidget extends StatefulWidget {
  const MapsDashboardWidget({super.key});

  @override
  State<MapsDashboardWidget> createState() => _MapsDashboardWidgetState();
}

class _MapsDashboardWidgetState extends State<MapsDashboardWidget> {
  final MapsDao _dao = AppDatabase.instance.mapsDao;
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;
  List<Map<String, dynamic>> _liveLocations = [];
  Map<String, dynamic>? _lastReport;
  bool _showGeofenceMenu = false;
  bool _showNavMenu = false;
  bool _isDrawingMode = false;
  final MapController _mapController = MapController();
  bool _isLocating = false;
  LatLng? _myLocation;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _sendTestReport();
  }

  void _connectWebSocket() {
    try {
      final baseUrl = ApiClient.instance.baseUrl.replaceAll(':8080', ':50051');
      final wsUrl = baseUrl.replaceFirst('http', 'ws');
      _wsChannel = WebSocketChannel.connect(Uri.parse('$wsUrl/api/v1/radar/live?device_id=flutter_dashboard'));
      _wsSub = _wsChannel!.stream.listen((msg) {
        if (!mounted) return;
        final data = jsonDecode(msg as String) as Map<String, dynamic>;
        setState(() {
          _liveLocations.insert(0, data);
          if (_liveLocations.length > 20) _liveLocations.removeLast();
        });
      });
    } catch (_) {}
  }

  Future<void> _locateMe() async {
    setState(() => _isLocating = true);
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final latLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(latLng, 15.0);
      setState(() => _myLocation = latLng);
    } catch (_) {}
    if (mounted) setState(() => _isLocating = false);
  }

  Future<void> _sendTestReport() async {
    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/radar/report', {
        'device_id': 'flutter_dashboard',
        'latitude': 37.9838,
        'longitude': 23.7275,
        'velocity': 0,
        'altitude': 100,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      if (mounted) setState(() => _lastReport = res);
    } catch (_) {}
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MapsDashboardHeader(wsChannel: _wsChannel),
          const SizedBox(height: 16),
          MapsReportBanner(lastReport: _lastReport),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: OsmMapWidget(
                    liveLocations: _liveLocations,
                    isDrawingMode: _isDrawingMode,
                    mapController: _mapController,
                    myLocation: _myLocation,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'nav_fab',
                        mini: true,
                        backgroundColor: EverforestColors.bg1.withOpacity(0.9),
                        child: const Icon(Icons.directions, color: EverforestColors.blue),
                        onPressed: () => setState(() { _showNavMenu = true; _showGeofenceMenu = false; }),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'geo_fab',
                        mini: true,
                        backgroundColor: EverforestColors.bg1.withOpacity(0.9),
                        child: const Icon(Icons.share_location, color: EverforestColors.green),
                        onPressed: () => setState(() { _showGeofenceMenu = true; _showNavMenu = false; }),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'my_loc_fab',
                        mini: true,
                        backgroundColor: EverforestColors.bg1.withOpacity(0.9),
                        child: _isLocating 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: EverforestColors.red))
                            : const Icon(Icons.my_location, color: EverforestColors.red),
                        onPressed: _locateMe,
                      ),
                    ],
                  ),
                ),
                if (_showNavMenu)
                  NavigationOverlay(onClose: () => setState(() => _showNavMenu = false)),
                if (_showGeofenceMenu)
                  GeofenceDrawerOverlay(
                    onClose: () => setState(() => _showGeofenceMenu = false),
                    isDrawingMode: _isDrawingMode,
                    onToggleDrawMode: () => setState(() => _isDrawingMode = !_isDrawingMode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
