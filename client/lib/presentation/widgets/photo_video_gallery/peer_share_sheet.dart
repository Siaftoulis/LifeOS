import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../theme/everforest_colors.dart';
import '../../../core/local_discovery_service.dart';
import '../../../core/p2p_transfer_service.dart';
import '../../../core/p2p_models.dart';
import 'gallery_item.dart';

class PeerShareSheet extends StatelessWidget {
  final GalleryItem item;
  final Function(P2PProgress?) onStartProgress;
  final VoidCallback onComplete;

  const PeerShareSheet({
    super.key,
    required this.item,
    required this.onStartProgress,
    required this.onComplete,
  });

  Future<void> _startFileSharing(BuildContext context, LocalPeer peer) async {
    File? fileToSend;

    // Show preparing overlay if it's a remote URL
    if (!item.isLocal) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: EverforestColors.green),
        ),
      );

      try {
        final response = await http.get(Uri.parse(item.pathOrUrl));
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${item.label}');
        await file.writeAsBytes(response.bodyBytes);
        fileToSend = file;
      } catch (e) {
        debugPrint("Download to temp file failed: $e");
      }

      if (Navigator.canPop(context)) Navigator.pop(context); // Pop loading
    } else {
      fileToSend = File(item.pathOrUrl);
    }

    if (fileToSend == null || !fileToSend.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File preparation failed.'), backgroundColor: EverforestColors.red),
      );
      return;
    }

    // Callback to trigger overlay
    onStartProgress(
      P2PProgress(
        fileName: item.label,
        bytesTransferred: 0,
        totalBytes: fileToSend.lengthSync(),
        isSender: true,
        speedMBs: 0,
        isCompleted: false,
      ),
    );

    // Close bottom sheet
    Navigator.pop(context);

    // Start sending
    await P2PTransferService.instance.sendFile(
      peer.address,
      peer.port,
      fileToSend,
      item.label,
    );

    onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<LocalPeer>>(
      valueListenable: LocalDiscoveryService.instance.peersNotifier,
      builder: (context, peers, _) {
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
                    'Select LocalSend Peer',
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
              const SizedBox(height: 8),
              if (peers.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: EverforestColors.green),
                      SizedBox(height: 16),
                      Text(
                        'Searching for peers on local network...',
                        style: TextStyle(color: EverforestColors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: peers.length,
                    itemBuilder: (context, idx) {
                      final peer = peers[idx];
                      return ListTile(
                        leading: const Icon(Icons.devices, color: EverforestColors.green),
                        title: Text(peer.name, style: const TextStyle(color: EverforestColors.fg)),
                        subtitle: Text('${peer.address}:${peer.port}', style: const TextStyle(color: EverforestColors.grey, fontSize: 11)),
                        trailing: const Icon(Icons.send, color: EverforestColors.green, size: 20),
                        onTap: () => _startFileSharing(context, peer),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
