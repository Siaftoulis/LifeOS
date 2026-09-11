import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/preferences_service.dart';
import 'theme/app_skin_manager.dart';
import 'auth_service.dart';
import 'core/p2p_transfer_service.dart';
import 'core/music_playback/android_media_bridge.dart';
import 'presentation/widgets/media_hub/media_hub_dashboard.dart';
import 'presentation/widgets/media_hub/music_library/music_dashboard_widget.dart';
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
  Map<String, dynamic>? _pendingWidgetLaunch;

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
    AndroidMediaBridge.latestLaunchIntent.addListener(_handleWidgetLaunchIntent);
    if (AndroidMediaBridge.latestLaunchIntent.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleWidgetLaunchIntent());
    }
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
    AndroidMediaBridge.latestLaunchIntent.removeListener(_handleWidgetLaunchIntent);
    _pollService.stop();
    P2PTransferService.instance.onReceiveRequest = null;
    _sessionGuard.detach();
    super.dispose();
  }

  void _handleWidgetLaunchIntent() {
    final args = AndroidMediaBridge.latestLaunchIntent.value;
    if (args == null) return;
    if (!_isUnlocked) {
      _pendingWidgetLaunch = args;
      return;
    }
    _executeWidgetLaunch(args);
  }

  void _executeWidgetLaunch(Map<String, dynamic> args) {
    final targetTab = args['target_tab'] as String? ?? 'music_player';
    final openNowPlaying = args['open_now_playing'] as bool? ?? (targetTab == 'music_player');

    if (targetTab == 'home') {
      spatialEngineKey.currentState?.navigateToModule('home');
      return;
    }

    spatialEngineKey.currentState?.navigateToModule('media_hub');

    int tabIndex = 0;
    switch (targetTab) {
      case 'movies':
        tabIndex = 1;
        break;
      case 'gallery':
        tabIndex = 2;
        break;
      case 'youtube':
        tabIndex = 3;
        break;
      case 'music':
      case 'music_player':
      default:
        tabIndex = 0;
        break;
    }
    MediaHubDashboard.switchTab(tabIndex);

    if (tabIndex == 0 && openNowPlaying) {
      Future.delayed(const Duration(milliseconds: 300), () {
        MusicDashboardWidget.openNowPlayingGlobal();
      });
    }
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
        if (_pendingWidgetLaunch != null) {
          final pending = _pendingWidgetLaunch!;
          _pendingWidgetLaunch = null;
          WidgetsBinding.instance.addPostFrameCallback((_) => _executeWidgetLaunch(pending));
        }
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
        AppSkinManager.currentSkinNotifier,
      ]),
      builder: (context, _) {
        final skin = AppSkinManager.currentSkin;
        return MaterialApp(
          navigatorKey: rootNavigatorKey,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          ),
          title: 'LifeOS',
          theme: skin.toThemeData(),
          showPerformanceOverlay: PreferencesService.showPerformanceOverlay.value,
          home: Builder(builder: (ctx) {
            return ValueListenableBuilder<List<List<String>>>(
              valueListenable: PreferencesService.layout,
              builder: (context, layout, _) {
                return ColoredBox(
                  color: skin.bg0,
                  child: LifeOSMainStack(
                    isUnlocked: _isUnlocked,
                    layout: layout,
                    onUnlock: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      _sessionGuard.attach();
                      setState(() => _isUnlocked = true);
                      if (_pendingWidgetLaunch != null) {
                        final pending = _pendingWidgetLaunch!;
                        _pendingWidgetLaunch = null;
                        WidgetsBinding.instance.addPostFrameCallback((_) => _executeWidgetLaunch(pending));
                      }
                    },
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
