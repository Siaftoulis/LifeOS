import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'photo_detail_screen.dart';
import 'backup_activity_panel.dart';

class GalleryGridWidget extends StatelessWidget {
  const GalleryGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: EverforestColors.bg0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Photo & Video Gallery', style: TextStyle(color: EverforestColors.fg, fontSize: 24, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Backups (+1pt/5 items)'),
                style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.bg2),
                onPressed: () => _showBackups(context),
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoDetailScreen())),
                  child: Container(
                    decoration: BoxDecoration(
                      color: EverforestColors.bg1,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: EverforestColors.bg2),
                    ),
                    child: Center(
                      child: Icon(
                        index % 5 == 0 ? Icons.videocam : Icons.photo,
                        color: EverforestColors.grey,
                        size: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  void _showBackups(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const BackupActivityPanel(),
    );
  }
}
