import 'package:flutter/material.dart';
import '../../widgets/hero_media.dart';

class GalleryView extends StatelessWidget {
  const GalleryView({super.key});

  @override Widget build(BuildContext context) {
    final items = List.generate(36, (i) => 'https://picsum.photos/400/400?random=$i');
    
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 250, crossAxisSpacing: 0, mainAxisSpacing: 0),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final url = items[i];
        final tag = 'gallery_hero_$i';
        return GestureDetector(
          onTap: () => Navigator.push(context, PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => HeroMedia(tag: tag, url: url),
          )),
          child: Hero(
            tag: tag,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(url, fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xCC09090B), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
