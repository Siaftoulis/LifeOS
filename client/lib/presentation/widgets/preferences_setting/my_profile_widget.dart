import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../auth_service.dart';
import '../common/user_avatar_with_frame.dart';

class MyProfileWidget extends StatefulWidget {
  const MyProfileWidget({super.key});

  @override
  State<MyProfileWidget> createState() => _MyProfileWidgetState();
}

class _MyProfileWidgetState extends State<MyProfileWidget> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _statusController = TextEditingController();
  final _avatarUrlController = TextEditingController();

  String _selectedFrame = 'none';
  String _selectedNameStyle = 'default';
  String _selectedAvatar = '';
  bool _isSaving = false;

  final List<String> _avatarPresets = [
    '👑', '⚡', '🚀', '🎧', '🌿', '🦊', '🥋', '💻', '🛡️', '🎨', '🎵', '🌟', '☕', '🎮'
  ];

  @override
  void initState() {
    super.initState();
    final profile = AuthService.instance.currentUser.value;
    if (profile != null) {
      _usernameController.text = profile.username;
      _displayNameController.text = profile.displayName;
      _statusController.text = profile.status;
      _selectedFrame = profile.frame.isNotEmpty ? profile.frame : 'none';
      _selectedNameStyle = profile.nameStyle.isNotEmpty ? profile.nameStyle : 'default';
      _selectedAvatar = profile.avatarAsset;
      if (_selectedAvatar.startsWith('http://') || _selectedAvatar.startsWith('https://')) {
        _avatarUrlController.text = _selectedAvatar;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _statusController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final newUsername = _usernameController.text.trim();
    final newDisplayName = _displayNameController.text.trim();
    final newStatus = _statusController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Το Username δεν μπορεί να είναι κενό'), backgroundColor: EverforestColors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await AuthService.instance.updateProfile(
        newUsername: newUsername,
        displayName: newDisplayName.isNotEmpty ? newDisplayName : newUsername,
        status: newStatus,
        avatarAsset: _selectedAvatar,
        frame: _selectedFrame,
        nameStyle: _selectedNameStyle,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Το προφίλ ενημερώθηκε επιτυχώς!'),
              backgroundColor: EverforestColors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Αποτυχία αποθήκευσης προφίλ.'),
              backgroundColor: EverforestColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: EverforestColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewDisplayName = _displayNameController.text.isNotEmpty 
        ? _displayNameController.text 
        : (_usernameController.text.isNotEmpty ? _usernameController.text : 'User');

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.bg2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: EverforestColors.green),
              SizedBox(width: 10),
              Text('Προφίλ & Εμφάνιση', style: TextStyle(color: EverforestColors.fg, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // LIVE PREVIEW CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: EverforestColors.bg0,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: EverforestColors.bg2),
            ),
            child: Row(
              children: [
                UserAvatarWithFrame(
                  avatarAsset: _selectedAvatar,
                  username: _usernameController.text,
                  frameId: _selectedFrame,
                  radius: 32,
                  isOnline: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewDisplayName,
                        style: UserNameStyles.apply(
                          _selectedNameStyle,
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${_usernameController.text}',
                        style: const TextStyle(color: EverforestColors.grey, fontSize: 13),
                      ),
                      if (_statusController.text.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: EverforestColors.bg2),
                          ),
                          child: Text(
                            _statusController.text,
                            style: const TextStyle(color: EverforestColors.aqua, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // EDIT USERNAME & DISPLAY NAME & STATUS
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: EverforestColors.fg),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Username (@login)',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    prefixIcon: Icon(Icons.alternate_email, color: EverforestColors.grey, size: 18),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _displayNameController,
                  style: const TextStyle(color: EverforestColors.fg),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    labelStyle: TextStyle(color: EverforestColors.grey),
                    prefixIcon: Icon(Icons.person_outline, color: EverforestColors.grey, size: 18),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _statusController,
            style: const TextStyle(color: EverforestColors.fg),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Status / Bio / Τίτλος',
              labelStyle: TextStyle(color: EverforestColors.grey),
              prefixIcon: Icon(Icons.info_outline, color: EverforestColors.grey, size: 18),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
            ),
          ),

          const SizedBox(height: 24),

          // AVATAR PRESET SELECTOR
          const Text('Επιλογή Avatar / Εικονιδίου', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._avatarPresets.map((emoji) {
                final isSelected = _selectedAvatar == emoji;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = emoji;
                      _avatarUrlController.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? EverforestColors.green.withValues(alpha: 0.2) : EverforestColors.bg0,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? EverforestColors.green : EverforestColors.bg2,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 12),
          TextField(
            controller: _avatarUrlController,
            style: const TextStyle(color: EverforestColors.fg, fontSize: 13),
            onChanged: (val) {
              setState(() {
                _selectedAvatar = val.trim();
              });
            },
            decoration: const InputDecoration(
              labelText: 'Ή επικόλληση URL εικόνας (https://...)',
              labelStyle: TextStyle(color: EverforestColors.grey),
              prefixIcon: Icon(Icons.link, color: EverforestColors.grey, size: 18),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
            ),
          ),

          const SizedBox(height: 24),

          // FRAME SELECTOR
          const Text('Επιλογή Frame (Πλαίσιο)', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserAvatarFrames.all.map((frame) {
              final isSelected = _selectedFrame == frame.id;
              return InkWell(
                onTap: () {
                  setState(() => _selectedFrame = frame.id);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? frame.colors.first.withValues(alpha: 0.15) : EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? frame.colors.first : EverforestColors.bg2,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: frame.colors),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        frame.label,
                        style: TextStyle(
                          color: isSelected ? EverforestColors.fg : EverforestColors.grey,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // NAME STYLE SELECTOR
          const Text('Στυλ Ονόματος (Name Styling)', style: TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserNameStyles.all.map((style) {
              final isSelected = _selectedNameStyle == style.id;
              return InkWell(
                onTap: () {
                  setState(() => _selectedNameStyle = style.id);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? EverforestColors.bg2 : EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? EverforestColors.green : EverforestColors.bg2,
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Text(
                    previewDisplayName,
                    style: style.styleBuilder(const TextStyle(fontSize: 13)),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 28),

          // ACTIONS
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.green,
              foregroundColor: EverforestColors.bg0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: EverforestColors.bg0, strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 20),
            label: Text(
              _isSaving ? 'ΑΠΟΘΗΚΕΥΣΗ...' : 'ΑΠΟΘΗΚΕΥΣΗ ΑΛΛΑΓΩΝ',
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: EverforestColors.red,
              side: const BorderSide(color: EverforestColors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              AuthService.instance.logout();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('ΑΠΟΣΥΝΔΕΣΗ / ΚΛΕΙΔΩΜΑ ΣΥΣΚΕΥΗΣ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
