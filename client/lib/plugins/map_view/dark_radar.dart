import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DarkRadar extends StatefulWidget {
  const DarkRadar({super.key});
  @override State<DarkRadar> createState() => _DarkRadarState();
}

class _DarkRadarState extends State<DarkRadar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  WebSocketChannel? _ws;
  bool _connected = false;
  String _lat = "37.7749", _lng = "-122.4194";

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))..repeat();
    _connectWS();
  }

  void _connectWS() async {
    try {
      _ws = WebSocketChannel.connect(Uri.parse('ws://localhost:50051/ws/location'));
      await _ws!.ready;
      if (!mounted) return;
      setState(() { _connected = true; _ctrl.duration = const Duration(seconds: 2); _ctrl.repeat(); });
      _ws!.stream.listen((d) {
        final j = jsonDecode(d);
        if (mounted) setState(() { _lat = j['lat'].toString(); _lng = j['lng'].toString(); });
      }, onDone: () => _setOffline(), onError: (_) => _setOffline());
    } catch (e) { _setOffline(); }
  }

  void _setOffline() { if (mounted) setState(() { _connected = false; _ctrl.duration = const Duration(milliseconds: 300); _ctrl.repeat(); }); }
  @override void dispose() { _ctrl.dispose(); _ws?.sink.close(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF09090B),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(animation: _ctrl, builder: (_, __) => Stack(alignment: Alignment.center, children: [
          Container(width: 80 + (_ctrl.value * 120), height: 80 + (_ctrl.value * 120), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00E5FF).withOpacity(1 - _ctrl.value), width: 2))),
          Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF00E5FF), boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.5), blurRadius: 16)])),
        ])),
        const SizedBox(height: 48),
        Text('LAT: $_lat  LNG: $_lng', style: const TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(_connected ? 'SYNC: LIVE WS' : 'SYNC: OFFLINE', style: TextStyle(color: _connected ? const Color(0xFF00E5FF) : Colors.red, letterSpacing: 1, fontSize: 10, height: 2)),
      ]),
    );
  }
}
