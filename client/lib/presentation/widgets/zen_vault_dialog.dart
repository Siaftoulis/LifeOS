import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/everforest_colors.dart';

class VaultInfo {
  final String name;
  final String path;
  final int noteCount;
  final bool isCurrent;

  VaultInfo({
    required this.name,
    required this.path,
    required this.noteCount,
    required this.isCurrent,
  });
}

class ZenVaultDialog extends StatefulWidget {
  final String currentVaultPath;
  final ValueChanged<String> onVaultSelected;

  const ZenVaultDialog({
    super.key,
    required this.currentVaultPath,
    required this.onVaultSelected,
  });

  @override
  State<ZenVaultDialog> createState() => _ZenVaultDialogState();
}

class _ZenVaultDialogState extends State<ZenVaultDialog> {
  final List<VaultInfo> _vaults = [];
  final TextEditingController _newVaultCtr = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanAvailableVaults();
  }

  @override
  void dispose() {
    _newVaultCtr.dispose();
    super.dispose();
  }

  void _scanAvailableVaults() {
    final List<String> candidatePaths = [
      'vault',
      'vault_personal',
      'vault_work',
      'vault_archive',
    ];

    if (!candidatePaths.contains(widget.currentVaultPath)) {
      candidatePaths.add(widget.currentVaultPath);
    }

    final List<VaultInfo> list = [];

    for (final path in candidatePaths) {
      final dir = Directory(path);
      int count = 0;
      if (dir.existsSync()) {
        final entities = dir.listSync(recursive: true);
        count = entities.where((e) => e is File && e.path.endsWith('.md')).length;
      }
      final name = path.split(RegExp(r'[/\\]')).last;
      list.add(VaultInfo(
        name: name,
        path: path,
        noteCount: count,
        isCurrent: path == widget.currentVaultPath,
      ));
    }

    if (mounted) {
      setState(() {
        _vaults.clear();
        _vaults.addAll(list);
      });
    }
  }

  void _createNewVault(String name) {
    final cleanName = name.trim().replaceAll(RegExp(r'[^\w\-_]'), '_');
    if (cleanName.isEmpty) return;

    final newPath = 'vault_$cleanName';
    final dir = Directory(newPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
      final readme = File('$newPath/README.md');
      readme.writeAsStringSync('# Welcome to $cleanName Vault\n\nCreated with Obsidian Zen Editor.');
    }

    widget.onVaultSelected(newPath);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EverforestColors.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.folder_shared, color: EverforestColors.green, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'MULTI-VAULT SWITCHER',
                      style: TextStyle(
                        color: EverforestColors.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: EverforestColors.grey, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: EverforestColors.bg2),
            const SizedBox(height: 12),
            const Text(
              'Select active Vault workspace:',
              style: TextStyle(color: EverforestColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _vaults.length,
                itemBuilder: (context, index) {
                  final vault = _vaults[index];
                  return Card(
                    color: vault.isCurrent ? EverforestColors.bg2 : EverforestColors.bg0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: vault.isCurrent ? EverforestColors.green : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        vault.isCurrent ? Icons.folder_special : Icons.folder,
                        color: vault.isCurrent ? EverforestColors.green : EverforestColors.blue,
                      ),
                      title: Text(
                        vault.name,
                        style: TextStyle(
                          color: vault.isCurrent ? EverforestColors.green : EverforestColors.fg,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${vault.noteCount} Markdown notes',
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 11),
                      ),
                      trailing: vault.isCurrent
                          ? const Chip(
                              label: Text('ACTIVE', style: TextStyle(color: EverforestColors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.transparent,
                              visualDensity: VisualDensity.compact,
                            )
                          : TextButton(
                              onPressed: () {
                                widget.onVaultSelected(vault.path);
                                Navigator.of(context).pop();
                              },
                              child: const Text('Open', style: TextStyle(color: EverforestColors.blue)),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: EverforestColors.bg2),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newVaultCtr,
                    style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'New Vault name...',
                      hintStyle: TextStyle(color: EverforestColors.grey, fontSize: 13),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                    ),
                    onSubmitted: _createNewVault,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _createNewVault(_newVaultCtr.text),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Create Vault'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EverforestColors.green,
                    foregroundColor: EverforestColors.bg0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
