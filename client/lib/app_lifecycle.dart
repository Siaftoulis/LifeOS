import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/preferences_service.dart';
import 'auth_service.dart';
import 'core/p2p_transfer_service.dart';
import 'global_keys.dart';
import 'p2p_dialog_handler.dart';
import 'notification_poll_service.dart';
import 'life_os_main_stack.dart';
import 'web_session_guard.dart';

class LifeOSMainApp extends StatefulWidget {
  const LifeOSMainApp({super.key});

  @override
  State<LifeOSMainApp> createState() => _LifeOSMainAppState();
}

class _LifeOSMainAppState extends State<LifeOSMainApp> with WidgetsBindingObserver {
  bool _isUnlocked = false;
  final _pollService = NotificationPollService();
  final _sessionGuard = WebSessionGuard(onExpire: () => AuthService.instance.logout());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    if (AuthService.isLocalhost) {
      AuthService.instance.ensureLocalhostUser();
      _isUnlocked = true;
    } else {
      _isUnlocked = AuthService.instance.isAuthenticated;
    }
    AuthService.instance.currentUser.addListener(_handleAuthChange);
    _pollService.start();
    P2PTransferService.instance.onReceiveRequest = _handleP2PReceiveRequest;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.instance.currentUser.removeListener(_handleAuthChange);
    _pollService.stop();
    P2PTransferService.instance.onReceiveRequest = null;
    _sessionGuard.detach();
    super.dispose();
  }

  void _handleP2PReceiveRequest(String senderName, String fileName, int fileSize, dynamic socket) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      P2PTransferService.instance.declineFile(socket);
      return;
    }
    P2PDialogHandler.handleReceiveRequest(context, senderName, fileName, fileSize, socket);
  }

  void _handleAuthChange() {
    final authenticated = AuthService.instance.isAuthenticated;
    if (authenticated != _isUnlocked) {
      setState(() {
        _isUnlocked = authenticated;
      });
      // ponytail: web-only — idle watchdog runs only while unlocked
      if (authenticated) {
        _sessionGuard.attach();
      } else {
        _sessionGuard.detach();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        PreferencesService.showPerformanceOverlay,
      ]),
      builder: (context, _) {
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          title: 'LifeOS',
          theme: ThemeData.dark(),
          showPerformanceOverlay: PreferencesService.showPerformanceOverlay.value,
          home: Builder(builder: (ctx) {
            return ValueListenableBuilder<List<List<String>>>(
              valueListenable: PreferencesService.layout,
              builder: (context, layout, _) {
                return LifeOSMainStack(
                  isUnlocked: _isUnlocked,
                  layout: layout,
                  onUnlock: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    _sessionGuard.attach();
                    setState(() => _isUnlocked = true);
                  },
                );
              },
            );
          }),
        );
      },
    );
  }
}
