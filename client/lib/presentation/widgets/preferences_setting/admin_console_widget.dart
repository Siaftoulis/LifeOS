import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import '../../../api_client.dart';
import '../../../auth_service.dart';

class AdminConsoleWidget extends StatefulWidget {
  const AdminConsoleWidget({super.key});

  @override
  State<AdminConsoleWidget> createState() => _AdminConsoleWidgetState();
}

class _AdminConsoleWidgetState extends State<AdminConsoleWidget> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'USER';
  bool _isCreating = false;
  bool _isLoadingUsers = true;
  bool _showAddUser = false;
  String _statusMsg = '';
  List<UserProfile> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await ApiClient.instance.getDaemon('/api/v1/auth/users');
      if (res is List && mounted) {
        setState(() {
          _users = res
              .whereType<Map>()
              .map((m) => UserProfile.fromJson(Map<String, dynamic>.from(m)))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createUser() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
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
        'email': email,
        'display_name': displayName.isNotEmpty ? displayName : user,
      });

      if (mounted) {
        if (res.containsKey('id') || res.containsKey('username')) {
          _statusMsg = 'Ο χρήστης δημιουργήθηκε επιτυχώς!';
          _usernameController.clear();
          _displayNameController.clear();
          _emailController.clear();
          _passwordController.clear();
          _showAddUser = false;
          _loadUsers();
        } else {
          _statusMsg = 'Σφάλμα κατά τη δημιουργία χρήστη.';
        }
      }
    } catch (e) {
      if (mounted) _statusMsg = 'Σφάλμα: Ο χρήστης υπάρχει ή τα στοιχεία δεν είναι έγκυρα.';
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _updateUserRole(String username, String newRole) async {
    try {
      await ApiClient.instance.patchDaemon('/api/v1/auth/users', {
        'username': username,
        'role': newRole,
      });
      _loadUsers();
    } catch (e) {
      debugPrint('Error updating role: $e');
    }
  }

  Future<void> _deleteUser(String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: EverforestColors.red),
            SizedBox(width: 8),
            Text('Διαγραφή Χρήστη', style: TextStyle(color: EverforestColors.red, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Είστε σίγουροι ότι θέλετε να διαγράψετε τον χρήστη "$username"; Όλα τα δεδομένα σύνδεσης του χρήστη θα αφαιρεθούν.',
          style: const TextStyle(color: EverforestColors.fg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('ΑΚΥΡΩΣΗ', style: TextStyle(color: EverforestColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: EverforestColors.red, foregroundColor: EverforestColors.bg0),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ΔΙΑΓΡΑΦΗ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.instance.deleteDaemon('/api/v1/auth/users?username=${Uri.encodeComponent(username)}');
      _loadUsers();
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUsername = AuthService.instance.currentUser.value?.username ?? '';

    return Container(
      decoration: BoxDecoration(
        color: EverforestColors.bg1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EverforestColors.red.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: EverforestColors.red, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Διαχείριση Χρηστών & Admin Console',
                  style: TextStyle(color: EverforestColors.red, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: EverforestColors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EverforestColors.red.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${_users.length} Χρήστες',
                  style: const TextStyle(color: EverforestColors.red, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_showAddUser ? Icons.close : Icons.person_add, color: EverforestColors.green),
                tooltip: _showAddUser ? 'Κλείσιμο' : 'Προσθήκη Χρήστη',
                onPressed: () => setState(() => _showAddUser = !_showAddUser),
              ),
            ],
          ),

          // Add User Expandable Form
          if (_showAddUser) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EverforestColors.bg2.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: EverforestColors.green.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Προσθήκη Νέου Χρήστη', style: TextStyle(color: EverforestColors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: EverforestColors.fg),
                          decoration: const InputDecoration(
                            labelText: 'Username *',
                            labelStyle: TextStyle(color: EverforestColors.fg),
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
                          decoration: const InputDecoration(
                            labelText: 'Display Name',
                            labelStyle: TextStyle(color: EverforestColors.fg),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          style: const TextStyle(color: EverforestColors.fg),
                          decoration: const InputDecoration(
                            labelText: 'Email (Google OAuth)',
                            labelStyle: TextStyle(color: EverforestColors.fg),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: EverforestColors.fg),
                          decoration: const InputDecoration(
                            labelText: 'Password / PIN *',
                            labelStyle: TextStyle(color: EverforestColors.fg),
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.green)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    dropdownColor: EverforestColors.bg1,
                    style: const TextStyle(color: EverforestColors.fg),
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      labelStyle: TextStyle(color: EverforestColors.fg),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'USER', child: Text('User (Family Member)')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Full Control)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRole = v);
                    },
                  ),
                  if (_statusMsg.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      _statusMsg,
                      style: TextStyle(
                        color: _statusMsg.contains('επιτυχώς') ? EverforestColors.green : EverforestColors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: _isCreating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: EverforestColors.bg0, strokeWidth: 2)) : const Icon(Icons.check),
                    label: const Text('ΔΗΜΙΟΥΡΓΙΑ ΧΡΗΣΤΗ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EverforestColors.green,
                      foregroundColor: EverforestColors.bg0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _isCreating ? null : _createUser,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Users List
          if (_isLoadingUsers)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: EverforestColors.red)))
          else if (_users.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Δεν βρέθηκαν χρήστες', style: TextStyle(color: EverforestColors.grey))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final user = _users[index];
                final isRootAdmin = user.username == 'panospds';
                final isCurrentUser = user.username == currentUsername;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: EverforestColors.bg0,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: user.role == 'ADMIN' ? EverforestColors.red.withValues(alpha: 0.3) : EverforestColors.bg2),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: user.role == 'ADMIN' ? EverforestColors.red.withValues(alpha: 0.2) : EverforestColors.green.withValues(alpha: 0.2),
                        child: Text(
                          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: user.role == 'ADMIN' ? EverforestColors.red : EverforestColors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user.displayName.isNotEmpty ? user.displayName : user.username,
                                  style: const TextStyle(color: EverforestColors.fg, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: EverforestColors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('ΕΣΕΙΣ', style: TextStyle(color: EverforestColors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${user.username}${user.email.isNotEmpty ? ' • ${user.email}' : ''}',
                              style: TextStyle(color: EverforestColors.fg.withValues(alpha: 0.6), fontSize: 12),
                            ),
                            if (user.status.isNotEmpty)
                              Text(
                                user.status,
                                style: TextStyle(color: EverforestColors.aqua.withValues(alpha: 0.8), fontSize: 11),
                              ),
                          ],
                        ),
                      ),

                      // Role Switcher Dropdown
                      if (!isRootAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: EverforestColors.bg1,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: EverforestColors.bg2),
                          ),
                          child: DropdownButton<String>(
                            value: user.role,
                            underline: const SizedBox(),
                            dropdownColor: EverforestColors.bg1,
                            style: const TextStyle(fontSize: 12),
                            items: const [
                              DropdownMenuItem(
                                value: 'USER',
                                child: Text('USER', style: TextStyle(color: EverforestColors.blue, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'ADMIN',
                                child: Text('ADMIN', style: TextStyle(color: EverforestColors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            onChanged: (newRole) {
                              if (newRole != null && newRole != user.role) {
                                _updateUserRole(user.username, newRole);
                              }
                            },
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: EverforestColors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('ROOT ADMIN', style: TextStyle(color: EverforestColors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),

                      const SizedBox(width: 8),

                      // Delete Button
                      if (!isRootAdmin && !isCurrentUser)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: EverforestColors.red, size: 20),
                          tooltip: 'Διαγραφή Χρήστη',
                          onPressed: () => _deleteUser(user.username),
                        )
                      else
                        const SizedBox(width: 40),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
