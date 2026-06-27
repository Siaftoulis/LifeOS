import 'dart:io';
import 'package:flutter/material.dart';
import '../../../theme/everforest_colors.dart';
import 'clock_widget.dart';
import 'notifications_feed.dart';
import '../../../auth_service.dart';

class LockScreenOverlay extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreenOverlay({super.key, required this.onUnlocked});

  @override
  State<LockScreenOverlay> createState() => _LockScreenOverlayState();
}

class _LockScreenOverlayState extends State<LockScreenOverlay> with SingleTickerProviderStateMixin {
  bool _showLoginForm = false;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _errorMsg = '';
  
  bool _isDesktop = false;

  @override
  void initState() {
    super.initState();
    try {
      _isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      _isDesktop = false;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleLoginForm(bool show) {
    if (_isDesktop) return; // Desktop form is always visible
    setState(() {
      _showLoginForm = show;
      _errorMsg = '';
      if (show) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _usernameController.clear();
        _passwordController.clear();
        _rememberMe = false;
      }
    });
  }

  Future<void> _handleLogin() async {
    final user = _usernameController.text.trim();
    final pass = _passwordController.text.trim();
    if (user.isEmpty || pass.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final success = await AuthService.instance.login(user, pass, rememberMe: _rememberMe);

      if (!mounted) return;

      if (success) {
        widget.onUnlocked();
      } else {
        setState(() {
          _isLoading = false;
          _errorMsg = 'Invalid username or password';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Widget _buildMainScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 80),
          const ClockWidget(),
          const SizedBox(height: 48),
          const Expanded(
            child: NotificationsFeed(),
          ),
          const SizedBox(height: 24),
          if (!_isDesktop)
            Opacity(
              opacity: _showLoginForm ? 0.0 : 1.0,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _toggleLoginForm(true),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.keyboard_double_arrow_up,
                        color: EverforestColors.green,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click or swipe up to login',
                        style: TextStyle(
                          color: EverforestColors.fg.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.shield, size: 64, color: EverforestColors.green),
            const SizedBox(height: 32),
            const Text(
              'SYSTEM LOGIN',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: EverforestColors.green,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: const TextStyle(color: EverforestColors.green),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: EverforestColors.green, width: 2)),
                prefixIcon: const Icon(Icons.person, color: EverforestColors.green),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: EverforestColors.fg),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: const TextStyle(color: EverforestColors.green),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: EverforestColors.bg2)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: EverforestColors.green, width: 2)),
                prefixIcon: const Icon(Icons.lock, color: EverforestColors.green),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: EverforestColors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              onSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: EverforestColors.green,
                    checkColor: EverforestColors.bg0,
                    side: const BorderSide(color: EverforestColors.bg2),
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _rememberMe = !_rememberMe;
                    });
                  },
                  child: Text(
                    'Remember Me',
                    style: TextStyle(
                      color: EverforestColors.fg.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMsg.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMsg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: EverforestColors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: EverforestColors.green,
                foregroundColor: EverforestColors.bg0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: EverforestColors.bg0, strokeWidth: 2))
                : const Text('AUTHENTICATE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            if (!_isDesktop) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => _toggleLoginForm(false),
                child: Text(
                  'CANCEL',
                  style: TextStyle(
                    color: EverforestColors.red.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return Scaffold(
        backgroundColor: EverforestColors.bg0,
        body: Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildMainScreen(),
            ),
            Container(
              width: 1,
              color: EverforestColors.bg2,
            ),
            Expanded(
              flex: 2,
              child: Container(
                color: EverforestColors.bg0.withValues(alpha: 0.95),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: _buildLoginFormContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Optimized Mobile Layout: Decoupled from nested viewInset animations
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (!_showLoginForm && details.primaryDelta! < -8) {
          _toggleLoginForm(true);
        } else if (_showLoginForm && details.primaryDelta! > 8) {
          _toggleLoginForm(false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true, // Leave false; handled at spatial wrapper level
        backgroundColor: EverforestColors.bg0,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Stack(
                      children: [
                        // 1. ISOLATED HEAVY GRAPHICS (Cached Bitmaps Layer)
                        RepaintBoundary(
                          child: _buildMainScreen(),
                        ),
                        
                        // 2. FORM I PUTS LAYER
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Visibility(
                                visible: _animationController.value > 0,
                                child: child!,
                              );
                            },
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                color: EverforestColors.bg0.withValues(alpha: 0.95),
                                child: SafeArea(
                                  child: Center(
                                    child: _buildLoginFormContent(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
