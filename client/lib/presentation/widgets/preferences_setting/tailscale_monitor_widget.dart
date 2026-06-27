import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

class TailscaleMonitorWidget extends StatefulWidget {
  const TailscaleMonitorWidget({super.key});

  @override
  State<TailscaleMonitorWidget> createState() => _TailscaleMonitorWidgetState();
}

class _TailscaleMonitorWidgetState extends State<TailscaleMonitorWidget> {
  List<dynamic> _nodes = [];
  bool _isLoadingNodes = false;
  String _nodesError = '';

  @override
  void initState() {
    super.initState();
    _fetchNodes();
  }

  Future<void> _fetchNodes() async {
    if (mounted) setState(() => _isLoadingNodes = true);
    try {
      final daemonUrl = ApiClient.discoverBaseUrl().then((baseUrl) async {
        final url = baseUrl.replaceAll(':8080', ':50051');
        final response = await http.get(Uri.parse('$url/api/v1/system/nodes')).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _nodes = data.where((n) {
                final name = (n['name']?.toString() ?? '').toLowerCase();
                return !name.contains('panel') && !name.contains('ingest');
              }).toList();
              _nodesError = '';
            });
          }
        } else {
          throw Exception('Status code ${response.statusCode}');
        }
      });
      await daemonUrl;
    } catch (e) {
      if (mounted) {
        setState(() {
          _nodesError = 'Daemon nodes scan offline';
          // Populate default mockup list for development verification
          _nodes = [
            {'ip': '100.76.247.27', 'name': 'pds-laptop-1', 'online': true},
            {'ip': '100.76.247.28', 'name': 'pds-mobile-android', 'online': false},
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingNodes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EverforestColors.bg1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: EverforestColors.bg2, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connected Node Peers', style: TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: EverforestColors.green, size: 18),
                  onPressed: _fetchNodes,
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: EverforestColors.bg2.withOpacity(0.5),
            indent: 16,
            endIndent: 16,
          ),
          if (_isLoadingNodes)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator(color: EverforestColors.green)),
            )
          else
            ListTile(
              leading: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _nodesError.isNotEmpty ? EverforestColors.red : EverforestColors.green,
                ),
              ),
              title: Text(_nodesError.isNotEmpty ? 'Tunnel Error' : 'Tunnel Connected', style: const TextStyle(color: EverforestColors.fg, fontSize: 12, fontFamily: 'JetBrainsMono', fontWeight: FontWeight.bold)),
              subtitle: Text('${_nodes.length} Active Relay Nodes', style: const TextStyle(color: EverforestColors.grey, fontSize: 10, fontFamily: 'JetBrainsMono')),
              trailing: _nodesError.isNotEmpty
                  ? Text(_nodesError, style: const TextStyle(color: EverforestColors.red, fontSize: 10, fontWeight: FontWeight.bold))
                  : const Text('SECURE', style: TextStyle(color: EverforestColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
