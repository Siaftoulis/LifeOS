import 'package:flutter/material.dart';
import '../../api_client.dart';

class MediaGallery extends StatefulWidget {
  const MediaGallery({super.key});
  @override State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  List<String> _assets = []; bool _loading = true;
  @override void initState() { super.initState(); _fetchAssets(); }

  Future<void> _fetchAssets() async {
    final res = await ApiClient.instance.post('/api/gallery/assets', {});
    if (mounted) setState(() { _assets = List<String>.from(res['assets'] ?? []); _loading = false; });
  }

  @override Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: Color(0xFF09090B), body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF))));
    if (_assets.isEmpty) return const Scaffold(backgroundColor: Color(0xFF09090B), body: Center(child: Text('NO MEDIA NODE DETECTED', style: TextStyle(color: Colors.white24, fontSize: 12, fontFamily: 'JetBrainsMono', letterSpacing: 2))));
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: GridView.builder(
        padding: EdgeInsets.zero, itemCount: _assets.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4, childAspectRatio: 1),
        itemBuilder: (c, i) => Container(
          color: const Color(0xFF121214),
          child: Stack(children: [
            const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.white10, size: 28)),
            Positioned(bottom: 4, left: 4, child: Text(_assets[i], style: const TextStyle(color: Colors.white24, fontSize: 9, fontFamily: 'JetBrainsMono'))),
          ]),
        ),
      ),
    );
  }
}
