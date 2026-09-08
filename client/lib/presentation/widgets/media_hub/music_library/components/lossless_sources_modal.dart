import 'package:flutter/material.dart';
import '../../../../../api_client.dart';
import '../../../../../theme/app_skin_manager.dart';

/// Modal bottom sheet for configuring Soulseek (slskd), Tidal, and Deezer lossless sources.
class LosslessSourcesModal extends StatefulWidget {
  const LosslessSourcesModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const LosslessSourcesModal(),
    );
  }

  @override
  State<LosslessSourcesModal> createState() => _LosslessSourcesModalState();
}

class _LosslessSourcesModalState extends State<LosslessSourcesModal> {
  final _slskdUrlCtrl = TextEditingController(text: 'http://localhost:5030');
  final _slskdApiKeyCtrl = TextEditingController();
  final _tidalTokenCtrl = TextEditingController();
  final _deezerArlCtrl = TextEditingController();

  bool _slskdEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _slskdUrlCtrl.dispose();
    _slskdApiKeyCtrl.dispose();
    _tidalTokenCtrl.dispose();
    _deezerArlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final res = await ApiClient.instance.getDaemonSlow('/api/v1/music/config');
      if (res is Map && mounted) {
        setState(() {
          if (res['slskd_url'] != null && (res['slskd_url'] as String).isNotEmpty) {
            _slskdUrlCtrl.text = res['slskd_url'] as String;
          }
          if (res['slskd_api_key'] != null) {
            _slskdApiKeyCtrl.text = res['slskd_api_key'] as String;
          }
          if (res['slskd_enabled'] != null) {
            _slskdEnabled = res['slskd_enabled'] != 'false';
          }
          if (res['tidal_token'] != null) {
            _tidalTokenCtrl.text = res['tidal_token'] as String;
          }
          if (res['deezer_arl'] != null) {
            _deezerArlCtrl.text = res['deezer_arl'] as String;
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testSlskdConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final res = await ApiClient.instance.postDaemonSlow('/api/v1/music/config/test-slskd', {
        'url': _slskdUrlCtrl.text.trim(),
        'api_key': _slskdApiKeyCtrl.text.trim(),
      });

      if (mounted) {
        final available = res is Map && res['available'] == true;
        setState(() {
          _isTesting = false;
          _testSuccess = available;
          _testResult = available
              ? 'Connected to Soulseek daemon at ${_slskdUrlCtrl.text.trim()}'
              : 'Could not connect. Ensure slskd is running at ${_slskdUrlCtrl.text.trim()}';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = 'Connection failed: $e';
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    try {
      await ApiClient.instance.postDaemonSlow('/api/v1/music/config', {
        'slskd_url': _slskdUrlCtrl.text.trim(),
        'slskd_api_key': _slskdApiKeyCtrl.text.trim(),
        'slskd_enabled': _slskdEnabled ? 'true' : 'false',
        'tidal_token': _tidalTokenCtrl.text.trim(),
        'deezer_arl': _deezerArlCtrl.text.trim(),
      });

      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lossless source credentials saved successfully'),
            backgroundColor: context.skin.bg1,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: context.skin.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = context.skin;

    return Container(
      decoration: BoxDecoration(
        color: skin.bg1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: skin.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.hub_rounded, color: skin.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lossless Sources & Integrations',
                          style: TextStyle(
                            color: skin.fg,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Configure Soulseek P2P, Tidal, & Deezer HiFi',
                          style: TextStyle(color: skin.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                // --- SECTION 1: Soulseek (slskd) ---
                _buildSectionHeader('SOULSEEK (SLSKD) P2P LOSSLESS', skin),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: skin.bg2.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable Soulseek Network',
                                  style: TextStyle(
                                    color: skin.fg,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Searches peers for pure FLAC releases',
                                  style: TextStyle(color: skin.textMuted, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _slskdEnabled,
                            activeThumbColor: skin.accent,
                            onChanged: (val) => setState(() => _slskdEnabled = val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _slskdUrlCtrl,
                        label: 'slskd Daemon URL',
                        hint: 'http://localhost:5030',
                        skin: skin,
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(
                        controller: _slskdApiKeyCtrl,
                        label: 'API Key (Optional)',
                        hint: 'Leave blank if unauthenticated',
                        skin: skin,
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isTesting ? null : _testSlskdConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              )
                            : Icon(Icons.bolt_rounded, size: 16, color: skin.accent),
                        label: Text(
                          _isTesting ? 'Testing...' : 'Test Soulseek Connection',
                          style: TextStyle(color: skin.accent, fontSize: 12.5),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: skin.accent.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      if (_testResult != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _testSuccess
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _testSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                                size: 14,
                                color: _testSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _testResult!,
                                  style: TextStyle(
                                    color: _testSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // --- SECTION 2: Tidal HiFi ---
                _buildSectionHeader('TIDAL HIFI AUTHENTICATION', skin),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: skin.bg2.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _tidalTokenCtrl,
                        label: 'Tidal Token / Client ID',
                        hint: 'Bearer / Session token',
                        skin: skin,
                        obscureText: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enables master-quality FLAC direct stream extraction from Tidal.',
                        style: TextStyle(color: skin.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // --- SECTION 3: Deezer HiFi ---
                _buildSectionHeader('DEEZER HIFI AUTHENTICATION', skin),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: skin.bg2.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _deezerArlCtrl,
                        label: 'Deezer ARL Cookie',
                        hint: 'arl=...',
                        skin: skin,
                        obscureText: true,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enables 1411kbps lossless FLAC streaming directly from Deezer.',
                        style: TextStyle(color: skin.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: skin.accent,
                    foregroundColor: skin.bg0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Configuration',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppSkin skin) {
    return Text(
      title,
      style: TextStyle(
        color: skin.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required AppSkin skin,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: skin.fg, fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: skin.fg, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: skin.textMuted.withValues(alpha: 0.5), fontSize: 12.5),
            filled: true,
            fillColor: skin.bg1,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: skin.accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
