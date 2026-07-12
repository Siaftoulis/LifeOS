import 'package:flutter/material.dart';
import 'theme/everforest_colors.dart';
import 'core/p2p_transfer_service.dart';
import 'core/p2p_models.dart';

class P2PDialogHandler {
  static void handleReceiveRequest(
    BuildContext context,
    String senderName,
    String fileName,
    int fileSize,
    dynamic socket,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: EverforestColors.bg1,
          title: const Text('Incoming File Transfer', style: TextStyle(color: EverforestColors.fg)),
          content: Text(
            '$senderName wants to send you "$fileName" (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB). Do you accept?',
            style: const TextStyle(color: EverforestColors.fg),
          ),
          actions: [
            TextButton(
              onPressed: () {
                P2PTransferService.instance.declineFile(socket);
                Navigator.pop(ctx);
              },
              child: const Text('Decline', style: TextStyle(color: EverforestColors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showProgressOverlay(context, fileName, fileSize);
                P2PTransferService.instance.acceptFile(socket, fileName, fileSize);
              },
              child: const Text('Accept', style: TextStyle(color: EverforestColors.green)),
            ),
          ],
        );
      },
    );
  }

  static void _showProgressOverlay(BuildContext context, String fileName, int fileSize) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ValueListenableBuilder<P2PProgress?>(
          valueListenable: P2PTransferService.instance.progressNotifier,
          builder: (context, progress, _) {
            if (progress == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.canPop(context)) Navigator.pop(context);
              });
              return const SizedBox();
            }

            return AlertDialog(
              backgroundColor: EverforestColors.bg1,
              title: const Text('Receiving File', style: TextStyle(color: EverforestColors.fg)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    progress.fileName,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress.percent,
                    color: EverforestColors.green,
                    backgroundColor: EverforestColors.bg2,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress.percent * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: EverforestColors.fg, fontSize: 11),
                      ),
                      Text(
                        '${progress.speedMBs.toStringAsFixed(2)} MB/s',
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
