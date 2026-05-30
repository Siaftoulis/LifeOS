import 'package:flutter/material.dart';

class HeroMedia extends StatelessWidget {
  final String tag;
  final String url;
  const HeroMedia({super.key, required this.tag, required this.url});

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: GestureDetector(
        onVerticalDragEnd: (d) { 
          if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context); 
        },
        child: Center(
          child: Hero(
            tag: tag,
            child: Image.network(url, fit: BoxFit.contain, loadingBuilder: (_, c, p) => p == null ? c : const CircularProgressIndicator(color: Color(0xFF00E5FF))),
          ),
        ),
      ),
    );
  }
}
