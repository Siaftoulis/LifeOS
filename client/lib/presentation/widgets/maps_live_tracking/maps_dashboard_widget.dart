import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:drift/drift.dart' show Value;
import '../../../api_client.dart';
import '../../../database/database.dart';
import '../../../database/maps_dao.dart';
import '../../../theme/everforest_colors.dart';
import 'geofence_drawer_overlay.dart';
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
  bool _isDrawingMode = false;
  final MapController _mapController = MapController();
  bool _isLocating = false;
  LatLng? _myLocation;
  StreamSubscription<Position>? _positionStreamSub;
  List<Geofence> _geofences = [];
  StreamSubscription? _geofenceSub;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _sendTestReport();
    _startLocationTracking();
    _geofenceSub = _dao.watchAllGeofences().listen((list) {
      if (mounted) {
        setState(() => _geofences = list);
      }
    });
  }

  Future<void> _startLocationTracking() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      if (mounted) {
        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((Position pos) {
      if (mounted) {
        setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
      }
    });
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
    _positionStreamSub?.cancel();
    _wsSub?.cancel();
    _wsChannel?.sink.close();
    _geofenceSub?.cancel();
    super.dispose();
  }

  void _onMapTap(LatLng point) {
    final nameController = TextEditingController();
    final radiusController = TextEditingController(text: '200');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EverforestColors.bg0,
        title: const Text('Create Geofence Zone', style: TextStyle(color: EverforestColors.fg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Zone Name (e.g. University)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: radiusController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: const InputDecoration(
                labelText: 'Radius (meters)',
                labelStyle: TextStyle(color: EverforestColors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: EverforestColors.grey)),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final radius = double.tryParse(radiusController.text) ?? 200.0;
              if (name.isNotEmpty) {
                await _dao.insertGeofence(GeofencesCompanion(
                  id: Value(DateTime.now().millisecondsSinceEpoch.toString()),
                  name: Value(name),
                  latitude: Value(point.latitude),
                  longitude: Value(point.longitude),
                  radius: Value(radius),
                  isActive: const Value(1),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                  isDirty: const Value(1),
                ));
                if (mounted) {
                  setState(() => _isDrawingMode = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Geofence "$name" created!')),
                  );
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: EverforestColors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                    geofences: _geofences,
                    onMapTap: _onMapTap,
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'geo_fab',
                        mini: true,
                        backgroundColor: EverforestColors.bg1.withOpacity(0.9),
                        child: const Icon(Icons.share_location, color: EverforestColors.green),
                        onPressed: () => setState(() { _showGeofenceMenu = true; }),
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
                if (_showGeofenceMenu)
                  GeofenceDrawerOverlay(
                    onClose: () => setState(() => _showGeofenceMenu = false),
                    isDrawingMode: _isDrawingMode,
                    onToggleDrawMode: () => setState(() => _isDrawingMode = !_isDrawingMode),
                    geofences: _geofences,
                    onToggleActive: (id, active) => _dao.updateGeofenceActive(id, active),
                    onDelete: (id) => _dao.deleteGeofence(id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
