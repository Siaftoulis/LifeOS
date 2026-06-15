import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';

class AdminConsoleWidget extends StatefulWidget {
  const AdminConsoleWidget({super.key});

  @override
  State<AdminConsoleWidget> createState() => _AdminConsoleWidgetState();
}

class _AdminConsoleWidgetState extends State<AdminConsoleWidget> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'USER';
  bool _isCreating = false;
  String _statusMsg = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    setState(() {
      _isCreating = true;
      _statusMsg = '';
    });

    try {
      final res = await ApiClient.instance.postDaemon('/api/v1/auth/users', {
        'username': user,
        'password': pass,
        'role': _selectedRole,
      });

      if (mounted) {
        if (res.containsKey('id')) {
          _statusMsg = 'User created successfully!';
          _usernameController.clear();
          _passwordController.clear();
        } else {
          _statusMsg = 'Error creating user.';
        }
      }
    } catch (e) {
      if (mounted) _statusMsg = 'Error: Conflict or invalid request.';
    }

    if (mounted) setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EverforestColors.red.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: EverforestColors.red),
              SizedBox(width: 8),
              Text('Admin Console', style: TextStyle(color: EverforestColors.red, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              labelText: 'New Username',
              labelStyle: TextStyle(color: EverforestColors.fg),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.red)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              labelText: 'New Password',
              labelStyle: TextStyle(color: EverforestColors.fg),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.red)),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            dropdownColor: EverforestColors.bg1,
            style: const TextStyle(color: EverforestColors.fg),
            decoration: const InputDecoration(
              labelText: 'Role',
              labelStyle: TextStyle(color: EverforestColors.fg),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
            ),
            items: const [
              DropdownMenuItem(value: 'USER', child: Text('User')),
              DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _selectedRole = v);
            },
          ),
          if (_statusMsg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _statusMsg,
              style: TextStyle(
                color: _statusMsg.contains('success') ? EverforestColors.green : EverforestColors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: EverforestColors.red,
              foregroundColor: EverforestColors.bg0,
            ),
            onPressed: _isCreating ? null : _createUser,
            child: _isCreating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: EverforestColors.bg0, strokeWidth: 2)) : const Text('CREATE USER'),
          ),
        ],
      ),
    );
  }
}
