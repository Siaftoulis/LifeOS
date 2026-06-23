import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../theme/everforest_colors.dart';
import 'gallery_item.dart';

class MetadataSheet extends StatelessWidget {
  final GalleryItem item;

  const MetadataSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final sizeFormatted = (item.sizeBytes / (1024 * 1024)).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aves Metadata Details',
                style: TextStyle(
                  color: EverforestColors.fg,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: EverforestColors.grey),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              children: [
                _buildMetaRow('File Name', item.label),
                _buildMetaRow('File Path', item.pathOrUrl),
                _buildMetaRow('File Size', '$sizeFormatted MB (${item.sizeBytes} bytes)'),
                _buildMetaRow('Resolution', item.resolution),
                _buildMetaRow('Date Taken', item.date.toLocal().toString()),
                _buildMetaRow('Camera Device', item.camera),
                _buildMetaRow('Lens Specs', item.lens),
                _buildMetaRow('Tags', item.tags.join(', ')),
                if (item.latitude != null && item.longitude != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Location Map',
                    style: TextStyle(
                      color: EverforestColors.fg,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(item.latitude!, item.longitude!),
                          initialZoom: 13.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.lifeos.client',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(item.latitude!, item.longitude!),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'GPS Coordinates: ${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: EverforestColors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: EverforestColors.fg, fontSize: 12),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
