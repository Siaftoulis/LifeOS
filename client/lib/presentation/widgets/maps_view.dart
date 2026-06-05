import 'package:flutter/material.dart';

class MapsView extends StatelessWidget {
  const MapsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.map_outlined, color: Color(0xFF00E5FF), size: 48),
            SizedBox(height: 16),
            Text('OFFLINE MAP ENGINE', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Lat: 37.9838 • Lng: 23.7275', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
