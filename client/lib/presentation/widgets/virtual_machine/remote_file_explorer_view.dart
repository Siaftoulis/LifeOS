import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';

class RemoteFileExplorerView extends StatelessWidget {
  const RemoteFileExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: EverforestColors.bg1, borderRadius: BorderRadius.circular(16), border: Border.all(color: EverforestColors.bg2)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: EverforestColors.yellow),
              const SizedBox(width: 8),
              const Text('Remote Explorer: /mnt/data', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.upload_file, color: EverforestColors.blue), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: EverforestColors.bg0, borderRadius: BorderRadius.circular(8)),
              child: ListView(
                children: const [
                  _FileItem('src', true),
                  _FileItem('docs', true),
                  _FileItem('main.py', false),
                  _FileItem('requirements.txt', false),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final String name;
  final bool isFolder;
  const _FileItem(this.name, this.isFolder);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(isFolder ? Icons.folder : Icons.insert_drive_file, color: isFolder ? EverforestColors.yellow : EverforestColors.grey),
      title: Text(name, style: const TextStyle(color: EverforestColors.fg)),
      trailing: const Icon(Icons.download, color: EverforestColors.green),
    );
  }
}
