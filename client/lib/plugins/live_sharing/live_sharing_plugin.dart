import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/base_plugin.dart';
import '../../api_client.dart';
import '../../theme/everforest_colors.dart';

class LiveSharingPlugin implements BasePlugin {
  @override String get pluginId => 'PLUG-LIVE';
  @override String get title => 'Live Sharing';
  @override IconData get icon => Icons.share;

  final List<Map<String, dynamic>> _locations = [];
  WebSocketChannel? _channel;
  StreamSubscription? _sub;

  @override
  Future<void> initialize(dynamic db, ApiClient api) async {
    try {
      final baseUrl = api.baseUrl.replaceAll(':8080', ':50051');
      final wsUrl = baseUrl.replaceFirst('http', 'ws');
      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl/api/v1/radar/live?device_id=flutter_client'));
      _sub = _channel!.stream.listen((msg) {
        final data = jsonDecode(msg as String) as Map<String, dynamic>;
        _locations.insert(0, data);
        if (_locations.length > 50) _locations.removeLast();
      });
    } catch (_) {}
  }

  @override
  Widget buildView(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: EverforestColors.green),
              ),
              const SizedBox(width: 8),
              const Text('Live Feed', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        Expanded(
          child: _locations.isEmpty
            ? const Center(child: Text('Waiting for location updates...', style: TextStyle(color: EverforestColors.grey)))
            : ListView.builder(
                itemCount: _locations.length,
                itemBuilder: (ctx, i) {
                  final loc = _locations[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: EverforestColors.cyan, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${loc['device_id'] ?? '?'}: ${(loc['latitude'] as num?)?.toStringAsFixed(4) ?? '?'}, ${(loc['longitude'] as num?)?.toStringAsFixed(4) ?? '?'}',
                            style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                          ),
                        ),
                        if (loc['velocity'] != null)
                          Text('${loc['velocity']} m/s', style: const TextStyle(color: EverforestColors.grey, fontSize: 11)),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }

  void dispose() {
    _sub?.cancel();
    _channel?.sink.close();
  }
}
