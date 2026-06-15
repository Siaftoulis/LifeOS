import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../auth_service.dart';

class MyProfileWidget extends StatefulWidget {
  const MyProfileWidget({super.key});

  @override
  State<MyProfileWidget> createState() => _MyProfileWidgetState();
}

class _MyProfileWidgetState extends State<MyProfileWidget> {
  final _displayNameController = TextEditingController();
  final _statusController = TextEditingController();
  final _avatarController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = AuthService.instance.currentUser.value;
    if (profile != null) {
      _displayNameController.text = profile.displayName;
      _statusController.text = profile.status;
      _avatarController.text = profile.avatarAsset;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _statusController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    final success = await AuthService.instance.updateProfile(
      displayName: _displayNameController.text,
      status: _statusController.text,
      avatarAsset: _avatarController.text,
    );
    setState(() => _isSaving = false);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: EverforestColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.person, color: EverforestColors.blue),
              SizedBox(width: 8),
              Text('My Profile', style: TextStyle(color: EverforestColors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              labelText: 'Display Name',
              labelStyle: TextStyle(color: EverforestColors.fg),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.blue)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _statusController,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              labelText: 'Status / Title',
              labelStyle: TextStyle(color: EverforestColors.fg),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.blue)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _avatarController,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              labelText: 'Avatar Image URL',
              labelStyle: TextStyle(color: EverforestColors.fg),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.blue)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.blue,
              foregroundColor: EverforestColors.bg0,
            ),
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: EverforestColors.bg0, strokeWidth: 2)) : const Text('SAVE PROFILE'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: EverforestColors.red,
              side: const BorderSide(color: EverforestColors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              AuthService.instance.logout();
            },
            child: const Text('LOGOUT / LOCK DEVICE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
