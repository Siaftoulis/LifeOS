import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'auth_service.dart';
import 'global_keys.dart';
import 'theme/everforest_colors.dart';

// ponytail: web-only idle session guard. Refresh already logs out (the JWT
// lives in memory only after the OAuth handoff), this adds: warn at 50 min
// idle, force logout at 60 min. Native builds use the no-op in the _io file.

class WebSessionGuard {
  WebSessionGuard({required this.onExpire});
  final VoidCallback onExpire;

  static const _timeout = Duration(hours: 1);
  static const _warnAt = Duration(minutes: 50);

  Timer? _timer;
  DateTime _lastActivity = DateTime.now();
  bool _running = false;
  bool _dialogOpen = false;

  void attach() {
    if (_running) return;
    _running = true;
    _lastActivity = DateTime.now();
    web.window.addEventListener('pointerdown', _listener);
    web.window.addEventListener('keydown', _listener);
    web.window.addEventListener('touchstart', _listener);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _check());
  }

  void detach() {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;
    if (_dialogOpen) {
      _dialogOpen = false;
      rootNavigatorKey.currentState?.pop();
    }
  }

  late final web.EventListener _listener = ((web.Event _) => _onActivity(_)).toJS;

  // ponytail: any input activity closes the warning dialog on its own
  void _onActivity(web.Event _) {
    _lastActivity = DateTime.now();
    if (_dialogOpen) {
      _dialogOpen = false;
      rootNavigatorKey.currentState?.pop();
    }
  }

  void _check() {
    if (!_running) return;
    if (!AuthService.instance.isAuthenticated) {
      _lastActivity = DateTime.now();
      return;
    }
    final idle = DateTime.now().difference(_lastActivity);
    if (idle >= _timeout) {
      onExpire();
      detach();
    } else if (idle >= _warnAt && !_dialogOpen) {
      _showWarn();
    }
  }

  void _showWarn() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    _dialogOpen = true;
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: EverforestColors.bg1,
        title: const Text('Είσαι ακόμα ενεργός;', style: TextStyle(color: EverforestColors.fg)),
        content: const Text(
          'Δεν υπάρχει δραστηριότητα για 50 λεπτά. Θα αποσυνδεθείς σε 10 λεπτά λόγω αδράνειας.',
          style: TextStyle(color: EverforestColors.fg),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _dialogOpen = false;
              Navigator.of(dialogCtx).pop();
              _lastActivity = DateTime.now();
            },
            child: const Text('Ναι, είμαι εδώ', style: TextStyle(color: EverforestColors.green)),
          ),
          TextButton(
            onPressed: () {
              _dialogOpen = false;
              Navigator.of(dialogCtx).pop();
              onExpire();
              detach();
            },
            child: const Text('Αποσύνδεση', style: TextStyle(color: EverforestColors.red)),
          ),
        ],
      ),
    );
  }
}
